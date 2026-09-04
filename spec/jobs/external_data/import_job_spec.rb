require 'rails_helper'

module ExternalData

  RSpec.describe ImportJob do
    let(:game) { create(:game, base_uri: 'https://example.com') }

    def player_fixtures(count)
      season = game.seasons.first || create(:season, game:)

      Array.new(count) do |i|
        ExternalData::Player.new(
          attributes: { name: "Player #{i}", country: 'US', external_id: "/players/#{i}", external_points: '100',
                        season: }
        )
      end
    end

    def fake_adapter(players:)
      Struct.new(:players, :upcoming_tournaments, keyword_init: true).new(players:, upcoming_tournaments: [])
    end

    def build_job_class(kind: :players, &fetch)
      fetch ||= ->(interface) { interface.update_players }
      Class.new(described_class) do
        define_method(:kind) { kind }
        define_method(:fetch) { |interface| fetch.call(interface) }
      end
    end

    describe 'abstract hooks' do
      subject(:job) { described_class.new }

      it 'raises when #kind is not overridden' do
        expect { job.send(:kind) }.to raise_error('#kind not implemented')
      end

      it 'raises when #fetch is not overridden' do
        expect { job.send(:fetch, nil) }.to raise_error('#fetch not implemented')
      end
    end

    describe '#game' do
      let(:job_class) { build_job_class }

      it 'finds the Game row for the given game_id' do
        job_class.perform_now(game_id: game.id, adapter: fake_adapter(players: []))

        expect(ExternalRequest.last.game).to eq(game)
      end

      it 'raises a semantic error instead of a bare RecordNotFound for an unknown game_id' do
        message = "#{job_class.name}: no Game row with id 'MISSING' — seed it before running this job."

        expect do
          job_class.perform_now(game_id: 'MISSING', adapter: fake_adapter(players: []))
        end.to raise_error(RuntimeError, message)
      end
    end

    describe '#adapter' do
      let(:job_class) { build_job_class }

      it 'uses the injected adapter instead of the game\'s own registered one' do
        adapter = fake_adapter(players: player_fixtures(2))

        expect { job_class.perform_now(game_id: game.id, adapter:) }.to change(::Player, :count).by(2)
      end

      it "falls back to the game's own registered adapter when none is injected" do
        adapter = fake_adapter(players: player_fixtures(1))
        allow(::Game).to receive(:find).with(game.id).and_return(game)
        allow(game).to receive(:adapter).and_return(adapter)

        expect { job_class.perform_now(game_id: game.id) }.to change(::Player, :count).by(1)
      end

      it 'cannot be carried through #perform_later, since it is not serializable' do
        adapter = fake_adapter(players: [])

        expect { job_class.perform_later(game_id: game.id, adapter:) }
          .to raise_error(ActiveJob::SerializationError)
      end

      it '#perform_later works with game_id: alone' do
        expect { job_class.perform_later(game_id: game.id) }.not_to raise_error
      end
    end

    describe '#perform' do
      let(:players) { player_fixtures(3) }
      let(:job_class) { build_job_class }
      let(:adapter) { fake_adapter(players:) }
      let(:perform_import) { -> { job_class.perform_now(game_id: game.id, adapter:) } }

      subject(:job) { job_class.new }

      it_behaves_like 'an external data import job'

      it 'processes every record in the batch' do
        expect { perform_import.call }.to change(::Player, :count).by(3)
      end

      it 'records how many records were processed on the ExternalRequest row' do
        perform_import.call

        expect(ExternalRequest.last.records_processed).to eq(3)
      end

      it 'records the fetch against the given kind' do
        perform_import.call

        expect(ExternalRequest.last.kind).to eq('players')
      end

      it 'records the fetch against the given game' do
        perform_import.call

        expect(ExternalRequest.last.game).to eq(game)
      end

      it 'records the fetch source as the game base uri' do
        perform_import.call

        expect(ExternalRequest.last.source_url).to eq('https://example.com')
      end

      it 'leaves requestable nil, since a batch import is not about one record' do
        perform_import.call

        expect(ExternalRequest.last.requestable).to be_nil
      end

      context 'when the subclass overrides #requestable' do
        let(:tournament) { create(:tournament) }
        let(:job_class) do
          record = tournament
          Class.new(build_job_class) do
            define_method(:requestable) { record }
          end
        end

        it 'links the ExternalRequest to the record the job ran for' do
          perform_import.call

          expect(ExternalRequest.last.requestable).to eq(tournament)
        end
      end

      describe 'when run a second time with the same batch' do
        it 'does not duplicate the persisted records' do
          perform_import.call

          expect { job_class.perform_now(game_id: game.id, adapter:) }.not_to change(::Player, :count)
        end

        it 'still records a second ExternalRequest row for the second run' do
          perform_import.call

          expect { job_class.perform_now(game_id: game.id, adapter:) }.to change(ExternalRequest, :count).by(1)
        end
      end

      describe 'when the fetch raises' do
        let(:job_class) { build_job_class { raise ArgumentError, 'boom' } }
        let(:adapter) { nil }

        it 'records the request as a failure' do
          suppress(StandardError) { perform_import.call }

          expect(ExternalRequest.last.status).to eq('failure')
        end

        it 're-raises the error to the caller' do
          expect { perform_import.call }.to raise_error(ArgumentError, 'boom')
        end
      end
    end

    describe 'retry behavior' do
      let(:job_class) { build_job_class { raise error } }
      let(:perform_import) { -> { job_class.perform_now(game_id: game.id, adapter: nil) } }

      subject(:job) { job_class.new }

      context 'when the fetch times out' do
        let(:error) { ExternalData::JsonApiClient::TimeoutError.new(url: 'https://example.com') }

        it 'is retried instead of propagating the error' do
          expect { perform_import.call }.not_to raise_error
        end
      end

      context 'when the fetch is rate limited' do
        let(:error) { ExternalData::JsonApiClient::RateLimitError.new(status: 429, url: 'https://example.com') }

        it 'is retried instead of propagating the error' do
          expect { perform_import.call }.not_to raise_error
        end
      end

      context 'when the fetch fails with a non-retryable HTTP error' do
        let(:error) { ExternalData::JsonApiClient::HttpError.new(status: 500, url: 'https://example.com') }

        it 'propagates the error instead of retrying' do
          expect { perform_import.call }.to raise_error(ExternalData::JsonApiClient::HttpError)
        end
      end
    end
  end

end
