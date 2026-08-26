require 'rails_helper'

module Admin

  module Api

    module Tournaments

      RSpec.describe 'Results' do
        let(:admin) { create(:user, :with_role, role: :admin) }

        describe '#update' do
          let(:tournament) { create(:tournament, game: create(:game, id: 'PTCG'), results_source_id: nil) }

          context 'when the user is not an admin' do
            let(:user) { create(:user) }

            before do
              sign_in user
            end

            it "hits Pundit's NotAuthorizedError path and does not enqueue a job" do
              expect do
                patch admin_api_tournament_results_path(tournament)
              end.not_to have_enqueued_job

              expect(response).to redirect_to(root_path)
            end
          end

          context 'when the user is an admin' do
            before do
              sign_in admin
            end

            context 'with results_source_id present' do
              let(:tournament) { create(:tournament, game: create(:game, id: 'PTCG'), results_source_id: '0070') }

              it 'enqueues the results import job with the tournament id' do
                expect do
                  patch admin_api_tournament_results_path(tournament)
                end.to have_enqueued_job(ExternalData::Ptcg::ImportResultsJob).with(tournament_id: tournament.id)
              end

              it 'returns 200' do
                patch admin_api_tournament_results_path(tournament)

                expect(response).to have_http_status(:ok)
              end
            end

            context 'with results_source_id blank' do
              it 'does not enqueue any job' do
                expect do
                  patch admin_api_tournament_results_path(tournament)
                end.not_to have_enqueued_job
              end

              it 'returns 422' do
                patch admin_api_tournament_results_path(tournament)

                expect(response).to have_http_status(:unprocessable_content)
              end
            end

            context 'when the tournament does not exist' do
              it 'returns 404' do
                patch admin_api_tournament_results_path(0)

                expect(response).to have_http_status(:not_found)
              end
            end
          end
        end
      end

    end

  end

end
