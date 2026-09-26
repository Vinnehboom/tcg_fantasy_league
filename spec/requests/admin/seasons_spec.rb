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
  end

end
