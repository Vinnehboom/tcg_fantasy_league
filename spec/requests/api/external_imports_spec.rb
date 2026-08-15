require 'rails_helper'

module Api

  RSpec.describe 'ExternalImports' do
    let(:admin) { create(:user, :with_role, role: :admin) }

    describe '#create' do
      before do
        create(:game, id: 'PTCG')
      end

      context 'when the user is not an admin' do
        let(:user) { create(:user) }

        before do
          sign_in user
        end

        it "hits Pundit's NotAuthorizedError path and does not enqueue a job" do
          expect do
            post api_external_imports_path, params: { game_id: 'PTCG', kind: 'players' }
          end.not_to have_enqueued_job

          expect(response).to redirect_to(root_path)
        end
      end

      context 'when the user is an admin' do
        before do
          sign_in admin
        end

        context 'with a recognized (game_id, kind) combination' do
          it 'enqueues the players import job' do
            expect do
              post api_external_imports_path, params: { game_id: 'PTCG', kind: 'players' }
            end.to have_enqueued_job(ExternalData::Ptcg::ImportPlayersJob)
          end

          it 'enqueues the tournaments import job' do
            expect do
              post api_external_imports_path, params: { game_id: 'PTCG', kind: 'tournaments' }
            end.to have_enqueued_job(ExternalData::Ptcg::ImportTournamentsJob)
          end

          it 'returns 200' do
            post api_external_imports_path, params: { game_id: 'PTCG', kind: 'players' }
            expect(response).to have_http_status(:ok)
          end
        end

        context 'with an unrecognized (game_id, kind) combination' do
          it 'returns 422' do
            post api_external_imports_path, params: { game_id: 'PTCG', kind: 'results' }
            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'does not enqueue any job' do
            expect do
              post api_external_imports_path, params: { game_id: 'PTCG', kind: 'results' }
            end.not_to have_enqueued_job
          end
        end
      end
    end
  end

end
