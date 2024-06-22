require 'rails_helper'

RSpec.describe 'Users' do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe '#show' do
    context 'when the user is allowed to view the user' do
      it 'shows the user' do
        get user_path(user)
        expect(response).to render_template('users/show')
      end
    end
  end
end
