require 'rails_helper'

module ExternalData

  RSpec.describe ImportJob do
    let(:game) { create(:game, base_uri: 'https://example.com') }

    def player_fixtures(count)
      Array.new(count) do |i|
        ExternalData::Player.new(
          attributes: { name: "Player #{i}", country: 'US', external_id: "/players/#{i}", external_points: '100' }
        )
      end
    end

    def fake_adapter(players:)
      Struct.new(:players, :upcoming_tournaments, keyword_init: true).new(players:, upcoming_tournaments: [])
    end

    def build_job_class(game:, adapter:, kind: :players, &fetch)
      fetch ||= ->(interface) { interface.update_players }
      Class.new(described_class) do
        define_method(:game) { game }
        define_method(:adapter) { adapter }
        define_method(:kind) { kind }
        define_method(:fetch) { |interface| fetch.call(interface) }
      end
    end

    describe 'abstract hooks' do
      subject(:job) { described_class.new }

      it 'raises when #game is not overridden' do
        expect { job.send(:game) }.to raise_error('#game not implemented')
      end

      it 'raises when #adapter is not overridden' do
        expect { job.send(:adapter) }.to raise_error('#adapter not implemented')
      end

      it 'raises when #kind is not overridden' do
        expect { job.send(:kind) }.to raise_error('#kind not implemented')
      end

      it 'raises when #fetch is not overridden' do
        expect { job.send(:fetch, nil) }.to raise_error('#fetch not implemented')
      end
    end

    describe '#perform' do
      let(:players) { player_fixtures(3) }
      let(:job_class) { build_job_class(game:, adapter: fake_adapter(players:)) }

      subject(:job) { job_class.new }

      it_behaves_like 'an external data import job'

      it 'processes every record in the batch' do
        expect { job.perform_now }.to change(::Player, :count).by(3)
      end

      it 'records how many records were processed on the ExternalRequest row' do
        job.perform_now

        expect(ExternalRequest.last.records_processed).to eq(3)
      end

      it 'records the fetch against the given kind' do
        job.perform_now

        expect(ExternalRequest.last.kind).to eq('players')
      end

      it 'records the fetch against the given game' do
        job.perform_now

        expect(ExternalRequest.last.game).to eq(game)
      end

      it 'records the fetch source as the game base uri' do
        job.perform_now

        expect(ExternalRequest.last.source_url).to eq('https://example.com')
      end

      it 'leaves requestable nil, since a batch import is not about one record' do
        job.perform_now

        expect(ExternalRequest.last.requestable).to be_nil
      end

      describe 'when run a second time with the same batch' do
        it 'does not duplicate the persisted records' do
          job.perform_now

          expect { job_class.new.perform_now }.not_to change(::Player, :count)
        end

        it 'still records a second ExternalRequest row for the second run' do
          job.perform_now

          expect { job_class.new.perform_now }.to change(ExternalRequest, :count).by(1)
        end
      end

      describe 'when the fetch raises' do
        let(:job_class) do
          build_job_class(game:, adapter: nil) { raise ArgumentError, 'boom' }
        end

        it 'records the request as a failure' do
          suppress(StandardError) { job.perform_now }

          expect(ExternalRequest.last.status).to eq('failure')
        end

        it 're-raises the error to the caller' do
          expect { job.perform_now }.to raise_error(ArgumentError, 'boom')
        end
      end
    end

    describe 'retry behavior' do
      subject(:job) { job_class.new }

      let(:job_class) do
        build_job_class(game:, adapter: nil) { raise error }
      end

      context 'when the fetch times out' do
        let(:error) { ExternalData::JsonApiClient::TimeoutError.new(url: 'https://example.com') }

        it 'is retried instead of propagating the error' do
          expect { job.perform_now }.not_to raise_error
        end
      end

      context 'when the fetch is rate limited' do
        let(:error) { ExternalData::JsonApiClient::RateLimitError.new(status: 429, url: 'https://example.com') }

        it 'is retried instead of propagating the error' do
          expect { job.perform_now }.not_to raise_error
        end
      end

      context 'when the fetch fails with a non-retryable HTTP error' do
        let(:error) { ExternalData::JsonApiClient::HttpError.new(status: 500, url: 'https://example.com') }

        it 'propagates the error instead of retrying' do
          expect { job.perform_now }.to raise_error(ExternalData::JsonApiClient::HttpError)
        end
      end
    end
  end

end
