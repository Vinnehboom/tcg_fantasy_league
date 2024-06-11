require 'rails_helper'

RSpec.describe 'Players' do
  describe '#index' do
    it 'shows all players' do
      get players_path
      expect(response).to render_template('players/index')
    end
  end
end
