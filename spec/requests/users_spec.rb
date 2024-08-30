require 'rails_helper'

RSpec.describe 'Users' do
  let(:user) { create(:user) }
  let(:game) { create(:game, id: 'PTCG') }

  before do
    sign_in user
  end

  describe '#show' do
    context 'when the user is allowed to view the user' do
      it 'shows the user' do
        get game_user_path(user, game:)
        expect(response).to render_template('users/show')
      end
    end
  end
end
