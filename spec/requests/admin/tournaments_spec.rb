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

        it "lists each tournament's results_source_id, so admins can spot which ones still need one" do
          create(:tournament, results_source_id: '0070')

          get admin_tournaments_path

          expect(response.body).to include('0070')
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

      context 'when the tournament has a results_source_id' do
        it 'shows the results-import trigger' do
          tournament = create(:tournament, results_source_id: '0070')

          get admin_tournament_path(tournament)

          expect(response.body).to include('data-controller="results-import-trigger"')
          expect(response.body).to include(results_import_admin_api_tournament_path(tournament))
        end
      end

      context 'when the tournament has no results_source_id' do
        it 'shows an explanatory message instead of the results-import trigger' do
          tournament = create(:tournament, results_source_id: nil)

          get admin_tournament_path(tournament)

          expect(response.body).to include(I18n.t('admin.tournaments.show.results_source_id_required'))
        end
      end
    end

    describe '#update' do
      let(:tournament) { create(:tournament, results_source_id: nil, game: create(:game, :ptcg)) }

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
        context 'with a valid id (the source confirms a real tournament)' do
          before do
            allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call)
              .with(hash_including(tournament_id: '0070')).and_return(128)
          end

          it "sets the tournament's results_source_id" do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(tournament.reload.results_source_id).to eq('0070')
          end

          it 'redirects to the show page' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(response).to redirect_to(admin_tournament_path(tournament))
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

          it 'flashes a blank-specific error' do
            patch admin_tournament_path(tournament), params: { results_source_id: '' }

            expect(flash[:alert]).to eq(I18n.t('admin.tournaments.update.blank'))
          end

          it 'never calls out to the results source' do
            allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call)

            patch admin_tournament_path(tournament), params: { results_source_id: '' }

            expect(ExternalData::Pokemon::Tcg::LabsTournament).not_to have_received(:call)
          end
        end

        context 'with an id the results source does not recognize' do
          before do
            allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call)
              .with(hash_including(tournament_id: 'bogus')).and_return(nil)
          end

          it 'does not change the tournament' do
            patch admin_tournament_path(tournament), params: { results_source_id: 'bogus' }

            expect(tournament.reload.results_source_id).to be_nil
          end

          it 'returns 422' do
            patch admin_tournament_path(tournament), params: { results_source_id: 'bogus' }

            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'flashes a not-found-specific error' do
            patch admin_tournament_path(tournament), params: { results_source_id: 'bogus' }

            expect(flash[:alert]).to eq(I18n.t('admin.tournaments.update.not_found'))
          end
        end

        context 'when the results source request fails (e.g. a 404 from the API)' do
          before do
            allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call)
              .with(hash_including(tournament_id: '0070'))
              .and_raise(ExternalData::JsonApiClient::HttpError.new(status: 404, url: 'https://mew.limitlesstcg.com'))
          end

          it 'does not change the tournament' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(tournament.reload.results_source_id).to be_nil
          end

          it 'returns 422 instead of a server error' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'flashes a verification-unavailable error, not a not-found error' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(flash[:alert]).to eq(I18n.t('admin.tournaments.update.verification_unavailable'))
          end
        end

        context "when the tournament's game has no registered verifier" do
          let(:tournament) { create(:tournament, results_source_id: nil) }

          it 'does not change the tournament' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(tournament.reload.results_source_id).to be_nil
          end

          it 'returns 422' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'flashes a verification-unavailable error' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(flash[:alert]).to eq(I18n.t('admin.tournaments.update.verification_unavailable'))
          end
        end

        context 'with a results_source_id already used by another tournament' do
          before do
            create(:tournament, results_source_id: '0070')
            allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call)
              .with(hash_including(tournament_id: '0070')).and_return(128)
          end

          it 'does not change the tournament' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(tournament.reload.results_source_id).to be_nil
          end

          it 'returns 422' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(response).to have_http_status(:unprocessable_content)
          end
        end

        context 'with an unchanged results_source_id' do
          let(:tournament) { create(:tournament, results_source_id: '0070', game: create(:game, :ptcg)) }

          before do
            allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call)
              .with(hash_including(tournament_id: '0070')).and_return(128)
          end

          it 'keeps the same results_source_id' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(tournament.reload.results_source_id).to eq('0070')
          end

          it 'redirects to the show page' do
            patch admin_tournament_path(tournament), params: { results_source_id: '0070' }

            expect(response).to redirect_to(admin_tournament_path(tournament))
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
