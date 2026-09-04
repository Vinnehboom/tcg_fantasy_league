require 'rails_helper'

module ExternalData

  RSpec.describe ImportResultsJob do
    subject(:job) { described_class.new }

    describe 'against the game\'s own registered adapter (no adapter injected)' do
      let(:tournament) { create(:tournament, game: create(:game, :ptcg), results_source_id: '0070') }
      let(:result) do
        ExternalData::Result.new(
          attributes: { player_external_id: '/players/1', player_name: 'Jodie Predovic', player_country: 'US',
                        placement: 1 }
        )
      end

      let(:perform_import) { -> { described_class.perform_now(tournament_id: tournament.id) } }

      before do
        allow(ExternalData::Pokemon::Tcg::LabsStandings).to receive(:call)
          .with(tournament_id: '0070').and_return([result])
      end

      context 'when the authoritative field size matches the number of results' do
        before do
          allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call)
            .with(tournament_id: '0070').and_return(1)
        end

        it_behaves_like 'an external data import job'

        it 'imports the fetched results as Result rows' do
          expect { perform_import.call }.to change(::Result, :count).by(1)
        end

        it 'links the ExternalRequest to the tournament it ran for' do
          perform_import.call

          expect(ExternalRequest.last.requestable).to eq(tournament)
        end

        it 'records the fetch against the results kind' do
          perform_import.call

          expect(ExternalRequest.last.kind).to eq('results')
        end
      end

      context 'when the authoritative field size differs from the number of processed results' do
        before do
          allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call)
            .with(tournament_id: '0070').and_return(128)
        end

        it "sets the tournament's field_size from the adapter's authoritative count, not the processed count" do
          perform_import.call

          expect(tournament.reload.field_size).to eq(128)
        end
      end
    end

    describe 'when the tournament has no results_source_id set' do
      let(:tournament) { create(:tournament, game: create(:game, :ptcg), results_source_id: nil) }

      it "raises the adapter's semantic error instead of fetching" do
        message = 'ExternalData::Pokemon::Tcg::Adapter: no results_source_id set on tournament ' \
                  "##{tournament.id} ('#{tournament.name}') — resolve it (e.g. via admin) before fetching " \
                  'Pokemon results.'

        expect { described_class.perform_now(tournament_id: tournament.id) }.to raise_error(RuntimeError, message)
      end

      it 'records the run as a failed ExternalRequest' do
        suppress(StandardError) { described_class.perform_now(tournament_id: tournament.id) }

        expect(ExternalRequest.last.status).to eq('failure')
      end
    end

    describe 'against an injected synthetic adapter (the demo composition roots\' path)' do
      let(:game) { create(:game) }
      let(:season) { create(:season, game:) }
      let(:shape) do
        ExternalData::Synthetic::Shape.new(
          score_range: (200..1600), score_curve: Demo::Curves::LADDER,
          player_count: 6, tournament_count: 1
        )
      end
      let(:adapter) { ExternalData::Synthetic::Adapter.new(game:, seed: 3, shape:) }
      let(:tournament) { create(:tournament, game:, external_id: '/tournaments/past-1') }

      let(:perform_import) { -> { described_class.perform_now(tournament_id: tournament.id, adapter:) } }

      before do
        season
        ImportPlayersJob.perform_now(game_id: game.id, adapter:)
      end

      it 'imports the fetched results as Result rows' do
        expect { perform_import.call }.to change(::Result, :count)
      end

      it 'names only players the players import already created, per the same seed and shape (Decisions D8)' do
        expect { perform_import.call }.not_to change(::Player, :count)
      end

      it "sets the tournament's field_size from the adapter, not the processed-results count" do
        expected_field_size = adapter.field_size(tournament:)

        perform_import.call

        expect(tournament.reload.field_size).to eq(expected_field_size)
      end
    end
  end

end
