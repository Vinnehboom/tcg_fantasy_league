require 'rails_helper'

module Admin

  RSpec.describe 'Seasons' do
    let(:admin) { create(:user, :with_role, role: :admin) }
    let(:game) { create(:game, :ptcg) }

    describe '#index' do
      context 'when the user is not an admin' do
        it 'sends the user away' do
          sign_in create(:user)

          get admin_game_seasons_path(game)

          expect(response).to redirect_to(root_path)
        end
      end

      context 'when the user is an admin' do
        before do
          sign_in admin
        end

        it 'lists only the seasons of that game' do
          create(:season, game:, label: 'Pokemon 2026')
          create(:season, game: create(:game, id: 'RIFT'), label: 'Riftbound 1')

          get admin_game_seasons_path(game)

          expect(response.body).to include('Pokemon 2026')
          expect(response.body).not_to include('Riftbound 1')
        end

        context 'when the game has no seasons' do
          it 'renders an empty state' do
            get admin_game_seasons_path(game)

            expect(response.body).to include('This game has no seasons yet.')
          end
        end
      end
    end

    describe '#new' do
      it 'renders the new template' do
        sign_in admin

        get new_admin_game_season_path(game)

        expect(response).to render_template('admin/seasons/new')
      end
    end

    describe '#create' do
      before do
        sign_in admin
      end

      context 'with a label and a start date' do
        let(:params) { { season: { label: 'Riftbound 1', start_date: '2026-01-01' } } }

        it 'adds an open season to the game' do
          post(admin_game_seasons_path(game), params:)

          expect(game.seasons.sole).to have_attributes(label: 'Riftbound 1', end_date: nil)
        end

        it 'goes back to the seasons of the game' do
          post(admin_game_seasons_path(game), params:)

          expect(response).to redirect_to(admin_game_seasons_path(game))
        end
      end

      context 'when the game already has an open season' do
        let(:params) { { season: { label: 'Pokemon 2027', start_date: '2026-09-01' } } }

        before do
          create(:season, game:, start_date: Date.new(2025, 9, 1), end_date: nil)
        end

        it 'does not add a second open season' do
          expect { post admin_game_seasons_path(game), params: }.not_to change(Season, :count)
        end

        it 'shows the form again with the overlap error' do
          post(admin_game_seasons_path(game), params:)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include('overlaps an existing season for this game')
        end
      end

      context 'without a label' do
        it 'does not add a season' do
          params = { season: { label: '', start_date: '2026-01-01' } }

          expect { post admin_game_seasons_path(game), params: }.not_to change(Season, :count)
        end
      end
    end

    describe '#edit' do
      it 'renders the edit template' do
        sign_in admin

        get edit_admin_game_season_path(game, create(:season, game:))

        expect(response).to render_template('admin/seasons/edit')
      end

      context 'when the season belongs to another game' do
        it 'is not found' do
          sign_in admin
          other_season = create(:season, game: create(:game, id: 'RIFT'))

          get edit_admin_game_season_path(game, other_season)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe '#update' do
      let(:season) { create(:season, game:, label: '2026', start_date: Date.new(2025, 9, 1), end_date: nil) }

      before do
        sign_in admin
      end

      context 'with an end date on or after the start date' do
        let(:params) { { season: { end_date: '2026-08-31' } } }

        it 'closes the season' do
          patch(admin_game_season_path(game, season), params:)

          expect(season.reload.end_date).to eq(Date.new(2026, 8, 31))
        end

        it 'goes back to the seasons of the game' do
          patch(admin_game_season_path(game, season), params:)

          expect(response).to redirect_to(admin_game_seasons_path(game))
        end
      end

      context 'with an end date before the start date' do
        let(:params) { { season: { end_date: '2025-08-31' } } }

        it 'keeps the season open' do
          patch(admin_game_season_path(game, season), params:)

          expect(season.reload.end_date).to be_nil
        end

        it 'shows the form again with the date error' do
          patch(admin_game_season_path(game, season), params:)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include('must be on or after the start date')
        end
      end

      context 'with a blank end date on a closed season' do
        it 'opens the season again' do
          season.update!(end_date: Date.new(2026, 8, 31))

          patch admin_game_season_path(game, season), params: { season: { end_date: '' } }

          expect(season.reload.end_date).to be_nil
        end
      end

      context 'with a new start date' do
        it 'keeps the original start date' do
          patch admin_game_season_path(game, season), params: { season: { label: '2026', start_date: '2026-01-01' } }

          expect(season.reload.start_date).to eq(Date.new(2025, 9, 1))
        end
      end
    end
  end

end
