require 'rails_helper'

RSpec.describe Admin::PlayersController do
  before { sign_in create(:user, :with_role) }

  describe '#show' do
    it 'raises RecordNotFound for a suppressed player\'s id' do
      suppressed = create(:player, :suppressed)

      expect { get :show, params: { id: suppressed.id } }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
