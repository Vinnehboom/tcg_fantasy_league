require 'rails_helper'

module Admin

  RSpec.describe 'Users' do
    let(:admin) { create(:user, :with_role, role: :admin) }
    let(:game) { create(:game, id: 'PTCG') }

    before do
      sign_in admin
    end

    describe '#show' do
      context 'when the user is allowed to view the user' do
        it 'shows the user' do
          get admin_user_path(create(:user))
          expect(response).to render_template('admin/users/show')
        end
      end
    end

    describe '#index' do
      context 'when the user is allowed to view the user' do
        it 'shows all users' do
          get admin_users_path
          expect(response).to render_template('admin/users/index')
        end
      end
    end
  end

end
