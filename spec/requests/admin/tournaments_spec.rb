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
        it "lists each tournament's name and shows the results_source_id trigger" do
          tournament = create(:tournament, name: 'Regional Championship')

          get admin_tournaments_path

          expect(response.body).to include('Regional Championship')
          expect(response.body).to include('data-controller="results-source-id"')
          expect(response.body).to include(results_source_id_admin_api_tournament_path(tournament))
        end
      end

      context 'when there are no tournaments' do
        it 'renders an empty state' do
          get admin_tournaments_path

          expect(response.body).to include(I18n.t('admin.tournaments.index.no_tournaments'))
        end
      end
    end
  end

end
