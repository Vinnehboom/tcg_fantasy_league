require 'rails_helper'

module ExternalData

  module Ptcg

    RSpec.describe ImportResultsJob do
      subject(:job) { described_class.new }

      describe 'when a PTCG game row exists' do
        let(:tournament) { create(:tournament, game: create(:game, id: 'PTCG'), results_source_id: '0070') }
        let(:result) do
          ExternalData::Result.new(
            attributes: { player_external_id: '/players/1', player_name: 'Jodie Predovic', player_country: 'US',
                          placement: 1 }
          )
        end

        before do
          allow(ExternalData::Pokemon::Tcg::LabsStandings).to receive(:call)
            .with(tournament_id: '0070').and_return([result])
        end

        context 'when the authoritative field size matches the number of results' do
          before do
            allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call)
              .with(tournament_id: '0070').and_return(1)
          end

          it { is_expected.to respond_to(:perform) }

          it 'creates exactly one ExternalRequest row per run' do
            expect do
              described_class.perform_now(tournament_id: tournament.id)
            end.to change(ExternalRequest, :count).by(1)
          end

          it 'imports the fetched results as Result rows' do
            expect { described_class.perform_now(tournament_id: tournament.id) }.to change(::Result, :count).by(1)
          end

          it 'links the ExternalRequest to the tournament it ran for' do
            described_class.perform_now(tournament_id: tournament.id)

            expect(ExternalRequest.last.requestable).to eq(tournament)
          end

          it 'records the fetch against the results kind' do
            described_class.perform_now(tournament_id: tournament.id)

            expect(ExternalRequest.last.kind).to eq('results')
          end
        end

        context 'when the authoritative field size differs from the number of processed results' do
          before do
            allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call)
              .with(tournament_id: '0070').and_return(128)
          end

          it "sets the tournament's field_size from the adapter's authoritative count, not the processed count" do
            described_class.perform_now(tournament_id: tournament.id)

            expect(tournament.reload.field_size).to eq(128)
          end
        end
      end

      describe 'when the tournament has no results_source_id set' do
        let(:tournament) { create(:tournament, game: create(:game, id: 'PTCG'), results_source_id: nil) }

        it "raises the adapter's semantic error instead of fetching" do
          message = 'ExternalData::Pokemon::Tcg::Adapter: no results_source_id set on tournament ' \
                    "##{tournament.id} ('#{tournament.name}') — resolve it (e.g. via admin) before fetching " \
                    'Pokemon results.'

          expect do
            described_class.perform_now(tournament_id: tournament.id)
          end.to raise_error(RuntimeError, message)
        end

        it 'records the run as a failed ExternalRequest' do
          suppress(StandardError) { described_class.perform_now(tournament_id: tournament.id) }

          expect(ExternalRequest.last.status).to eq('failure')
        end
      end

      describe 'when no PTCG game row exists' do
        let(:tournament) { create(:tournament, results_source_id: '0070') }

        it 'raises a semantic error instead of a bare RecordNotFound' do
          message = "ExternalData::Ptcg::ImportResultsJob: no Game row with id 'PTCG' — seed it before running " \
                    'this job.'

          expect do
            described_class.perform_now(tournament_id: tournament.id)
          end.to raise_error(RuntimeError, message)
        end
      end
    end

  end

end
