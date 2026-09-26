require 'rails_helper'

module ExternalData

  RSpec.describe ImportPlayersJob do
    subject(:job) { described_class.new }

    describe 'against the game\'s own registered adapter (no adapter injected)' do
      describe 'when a PTCG game row exists' do
        let(:season) do
          game = create(:game, :ptcg)
          create(:season, game:, start_date: 1.month.ago.to_date, end_date: 1.month.from_now.to_date, label: '2026')
        end
        let(:player) do
          ExternalData::Player.new(
            attributes: { name: 'Jodie Predovic', country: 'TF', external_id: '/players/5', external_points: '791',
                          season: }
          )
        end
        let(:perform_import) { -> { described_class.perform_now(game_id: 'PTCG') } }

        before do
          season
          allow(ExternalData::Pokemon::Tcg::LabsPlayers).to receive(:call).and_return([player])
        end

        it_behaves_like 'an external data import job'

        it 'imports the fetched players' do
          expect { perform_import.call }.to change(::Player, :count).by(1)
        end

        it 'tags the imported player\'s score with the current season' do
          perform_import.call

          expect(::Player.last.external_scores.last.player_season.season).to eq(season)
        end

        it 'records the fetch against the players kind' do
          perform_import.call

          expect(ExternalRequest.last.kind).to eq('players')
        end

        describe 'when the fetched player is already suppressed' do
          before { season }

          let(:suppressed_player) do
            create(:player, :without_scores, :suppressed, game: Game.find('PTCG'),
                                                          external_id: player.external_id, name: 'Existing Name')
          end

          it 'leaves the suppression in place across a subsequent import run' do
            suppressed_player
            perform_import.call
            perform_import.call

            expect(::Player.where(external_id: player.external_id).count).to eq(1)
          end

          it 'does not overwrite the existing name' do
            suppressed_player
            perform_import.call

            expect(suppressed_player.reload.raw_name).to eq('Existing Name')
          end

          it 'does not record a new score' do
            suppressed_player

            expect { perform_import.call }.not_to change(ExternalScore, :count)
          end
        end
      end

      describe 'when no Game row exists for the given id' do
        it 'raises a semantic error instead of a bare RecordNotFound' do
          message = "ExternalData::ImportPlayersJob: no Game row with id 'PTCG' — seed it before running this job."

          expect { described_class.perform_now(game_id: 'PTCG') }.to raise_error(RuntimeError, message)
        end
      end
    end

    describe 'against an injected synthetic adapter (the demo composition roots\' path)' do
      let(:game) { create(:game) }
      let(:season) { create(:season, game:) }
      let(:shape) do
        Demo::Shape.new(
          score_range: (200..1600), score_curve: Demo::Curves::LADDER,
          player_count: 5, tournament_count: 2
        )
      end
      let(:adapter) { ExternalData::Synthetic::Adapter.new(game:, seed: 1, shape:) }
      let(:perform_import) { -> { described_class.perform_now(game_id: game.id, adapter:) } }

      before { season }

      it 'imports the requested number of players, ignoring the game\'s own registered adapter' do
        expect { perform_import.call }.to change(::Player, :count).by(5)
      end

      context 'when the configured adapter_builder would raise if called' do
        before do
          @previous_adapter_builder = Rails.application.config.x.external_data.adapter_builder
          Rails.application.config.x.external_data.adapter_builder = lambda do |**|
            raise 'an injected adapter must never fall back to the configured builder'
          end
        end

        after do
          Rails.application.config.x.external_data.adapter_builder = @previous_adapter_builder
        end

        it 'never reads it, since the adapter is already injected' do
          expect { perform_import.call }.not_to raise_error
        end
      end
    end
  end

end
