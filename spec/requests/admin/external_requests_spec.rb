require 'rails_helper'

module Admin

  RSpec.describe 'ExternalRequests' do
    let(:admin) { create(:user, :with_role, role: :admin) }
    let(:game_a) { create(:game, id: 'AAAA', name: 'Aaa Game') }
    let(:game_b) { create(:game, id: 'BBBB', name: 'Bbb Game') }

    before do
      sign_in admin
    end

    describe '#index' do
      it 'renders the index template' do
        get admin_external_requests_path

        expect(response).to render_template('admin/external_requests/index')
      end

      context 'when no game param is given' do
        it 'defaults to the alphabetically-first game' do
          create(:external_request, :failure, game: game_a, error: 'error-only-in-a')
          create(:external_request, :failure, game: game_b, error: 'error-only-in-b')

          get admin_external_requests_path

          expect(response.body).to include('error-only-in-a')
          expect(response.body).not_to include('error-only-in-b')
        end
      end

      context 'when a game param is given' do
        it 'shows only that game\'s requests' do
          create(:external_request, :failure, game: game_a, error: 'error-only-in-a')
          create(:external_request, :failure, game: game_b, error: 'error-only-in-b')

          get admin_external_requests_path(game: game_b.id)

          expect(response.body).to include('error-only-in-b')
          expect(response.body).not_to include('error-only-in-a')
        end

        it 'shows a tab for every game' do
          game_a
          game_b

          get admin_external_requests_path(game: game_a.id)

          expect(response.body).to include(game_a.name)
          expect(response.body).to include(game_b.name)
        end
      end

      context 'when the game param does not match any game' do
        it 'falls back to the alphabetically-first game' do
          create(:external_request, :failure, game: game_a, error: 'error-only-in-a')

          get admin_external_requests_path(game: 'does-not-exist')

          expect(response.body).to include('error-only-in-a')
        end
      end

      context 'when there are no games at all' do
        it 'renders an empty state instead of a table' do
          get admin_external_requests_path

          expect(response.body).to include(I18n.t('admin.external_requests.index.no_games'))
        end
      end
    end
  end

end
