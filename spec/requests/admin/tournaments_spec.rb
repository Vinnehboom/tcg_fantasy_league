require 'rails_helper'

module Admin

  RSpec.describe 'Tournaments' do
    let(:admin) { create(:user, :with_role, role: :admin) }

    before do
      sign_in admin
    end

    describe '#index' do
      it 'renders the index template' do
        get admin_tournaments_path

        expect(response).to render_template('admin/tournaments/index')
      end

      context 'when tournaments exist' do
        it "lists each tournament's name, linked to its show page" do
          tournament = create(:tournament, name: 'Regional Championship')

          get admin_tournaments_path

          expect(response.body).to include('Regional Championship')
          expect(response.body).to include(admin_tournament_path(tournament))
        end
      end

      context 'when there are no tournaments' do
        it 'renders an empty state' do
          get admin_tournaments_path

          expect(response.body).to include(I18n.t('admin.tournaments.index.no_tournaments'))
        end
      end
    end

    describe '#show' do
      it 'renders the show template' do
        tournament = create(:tournament)

        get admin_tournament_path(tournament)

        expect(response).to render_template('admin/tournaments/show')
      end

      it "displays the tournament's results_source_id" do
        tournament = create(:tournament, results_source_id: '0070')

        get admin_tournament_path(tournament)

        expect(response.body).to include('0070')
      end

      context 'when the tournament does not exist' do
        it 'returns 404' do
          get admin_tournament_path(0)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe '#update' do
      let(:tournament) { create(:tournament, results_source_id: nil) }

      context 'when the user is not an admin' do
        let(:user) { create(:user) }

        before { sign_in user }

        it "does not change the tournament's results_source_id" do
          patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

          expect(tournament.reload.results_source_id).to be_nil
        end

        it 'redirects to root' do
          patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

          expect(response).to redirect_to(root_path)
        end
      end

      context 'when the user is an admin' do
        context 'with a bare id' do
          it "sets the tournament's results_source_id" do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(tournament.reload.results_source_id).to eq('0070')
          end

          it 'redirects to the show page' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(response).to redirect_to(admin_tournament_path(tournament))
          end
        end

        context 'with a full URL' do
          let(:tournament) { create(:tournament, results_source_id: nil, game: create(:game, :ptcg)) }

          it 'extracts the id and sets it' do
            patch admin_tournament_path(tournament),
                  params: { results_source_id: 'https://labs.limitlesstcg.com/0070/standings' }

            expect(tournament.reload.results_source_id).to eq('0070')
          end
        end

        context 'with a blank results_source_id' do
          it 'does not change the tournament' do
            patch admin_tournament_path(tournament), params: { results_source_id: '' }

            expect(tournament.reload.results_source_id).to be_nil
          end

          it 'returns 422' do
            patch admin_tournament_path(tournament), params: { results_source_id: '' }

            expect(response).to have_http_status(:unprocessable_content)
          end
        end

        context 'with a results_source_id already used by another tournament' do
          before { create(:tournament, results_source_id: '0070') }

          it 'does not change the tournament' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(tournament.reload.results_source_id).to be_nil
          end

          it 'returns 422' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(response).to have_http_status(:unprocessable_content)
          end
        end

        context 'when the tournament does not exist' do
          it 'returns 404' do
            patch admin_tournament_path(0), params: { results_source_id: '0070' }

            expect(response).to have_http_status(:not_found)
          end
        end
      end
    end
  end

end
