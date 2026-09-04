require 'rails_helper'

module ExternalData

  RSpec.describe ImportTournamentsJob do
    subject(:job) { described_class.new }

    describe 'against the game\'s own registered adapter (no adapter injected)' do
      describe 'when a PTCG game row exists' do
        let(:tournament) do
          ExternalData::Tournament.new(
            attributes: { name: 'WC 2024', country: 'US', external_id: '/tournaments/1',
                          starting_date: Faker::Date.forward }
          )
        end
        let(:perform_import) { -> { described_class.perform_now(game_id: 'PTCG') } }

        before do
          create(:game, :ptcg)
          allow(ExternalData::Pokemon::Tcg::Tournaments).to receive(:upcoming_tournaments).and_return([tournament])
        end

        it_behaves_like 'an external data import job'

        it 'imports the scraped upcoming tournaments' do
          expect { perform_import.call }.to change(::Tournament, :count).by(1)
        end

        it 'records the fetch against the tournaments kind' do
          perform_import.call

          expect(ExternalRequest.last.kind).to eq('tournaments')
        end
      end

      describe 'when no Game row exists for the given id' do
        it 'raises a semantic error instead of a bare RecordNotFound' do
          message = "ExternalData::ImportTournamentsJob: no Game row with id 'PTCG' — " \
                    'seed it before running this job.'

          expect { described_class.perform_now(game_id: 'PTCG') }.to raise_error(RuntimeError, message)
        end
      end
    end

    describe 'against an injected synthetic adapter (the demo composition roots\' path)' do
      let(:game) { create(:game) }
      let(:shape) do
        ExternalData::Synthetic::Shape.new(
          score_range: (200..1600), score_curve: Demo::Curves::LADDER,
          player_count: 4, tournament_count: 3
        )
      end
      let(:adapter) { ExternalData::Synthetic::Adapter.new(game:, seed: 5, shape:) }

      let(:perform_import) { -> { described_class.perform_now(game_id: game.id, adapter:) } }

      it 'imports the requested number of upcoming tournaments' do
        expect { perform_import.call }.to change(::Tournament, :count).by(3)
      end

      it 'imports only tournaments at least 7 days out' do
        perform_import.call

        expect(::Tournament.where(game:).pluck(:starting_date)).to all(be >= 7.days.from_now.to_date)
      end
    end
  end

end
