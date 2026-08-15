require 'rails_helper'

module Admin

  RSpec.describe 'Games' do
    let(:admin) { create(:user, :with_role, role: :admin) }

    before do
      sign_in admin
    end

    describe '#show' do
      context 'when the game exists' do
        let(:game) { create(:game, id: 'PTCG') }

        it 'shows the game' do
          get admin_game_path(game)
          expect(response).to render_template('admin/games/show')
        end

        it 'shows the import trigger buttons' do
          get admin_game_path(game)
          expect(response.body).to include('data-controller="external-import-trigger"')
        end
      end

      context 'when the game does not exist' do
        it 'returns 404' do
          get admin_game_path('NOPE')
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

end
