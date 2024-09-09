require 'rails_helper'

module Admin

  RSpec.describe 'Users' do
    let(:admin) { create(:user, :with_role, role: :admin) }
    let(:game) { create(:game, id: 'PTCG') }

    before do
      sign_in admin
    end

    describe '#show' do
      it 'shows the participation' do
        get admin_participation_path(create(:participation))
        expect(response).to render_template('admin/participations/show')
      end
    end

    describe '#index' do
      it 'shows all participations' do
        get admin_participations_path
        expect(response).to render_template('admin/participations/index')
      end
    end
  end

end
