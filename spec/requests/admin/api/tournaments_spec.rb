require 'rails_helper'

module Admin

  module Api

    RSpec.describe 'Tournaments' do
      let(:admin) { create(:user, :with_role, role: :admin) }
      let(:tournament) { create(:tournament, results_source_id: nil) }

      describe '#results_source_id' do
        context 'when the user is not an admin' do
          let(:user) { create(:user) }

          before do
            sign_in user
          end

          it "hits Pundit's NotAuthorizedError path and does not change the tournament" do
            patch results_source_id_admin_api_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(tournament.reload.results_source_id).to be_nil
            expect(response).to redirect_to(root_path)
          end
        end

        context 'when the user is an admin' do
          before do
            sign_in admin
          end

          context 'with a present results_source_id' do
            it "sets the tournament's results_source_id" do
              patch results_source_id_admin_api_tournament_path(tournament), params: { results_source_id: '0070' }

              expect(tournament.reload.results_source_id).to eq('0070')
            end

            it 'returns 200' do
              patch results_source_id_admin_api_tournament_path(tournament), params: { results_source_id: '0070' }

              expect(response).to have_http_status(:ok)
            end
          end

          context 'with a blank results_source_id' do
            it 'does not change the tournament' do
              patch results_source_id_admin_api_tournament_path(tournament), params: { results_source_id: '' }

              expect(tournament.reload.results_source_id).to be_nil
            end

            it 'returns 422' do
              patch results_source_id_admin_api_tournament_path(tournament), params: { results_source_id: '' }

              expect(response).to have_http_status(:unprocessable_content)
            end
          end

          context 'with a results_source_id already used by another tournament' do
            before { create(:tournament, results_source_id: '0070') }

            it 'does not change the tournament' do
              patch results_source_id_admin_api_tournament_path(tournament), params: { results_source_id: '0070' }

              expect(tournament.reload.results_source_id).to be_nil
            end

            it 'returns 422' do
              patch results_source_id_admin_api_tournament_path(tournament), params: { results_source_id: '0070' }

              expect(response).to have_http_status(:unprocessable_content)
            end
          end

          context 'when the tournament does not exist' do
            it 'returns 404' do
              patch results_source_id_admin_api_tournament_path(0), params: { results_source_id: '0070' }

              expect(response).to have_http_status(:not_found)
            end
          end
        end
      end
    end

  end

end
