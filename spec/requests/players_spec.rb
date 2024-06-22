require 'rails_helper'

RSpec.describe 'Players' do
  let(:game) { create(:game) }

  describe '#index' do
    it 'shows all players' do
      get game_players_path(game: game.name)
      expect(response).to render_template('players/index')
    end
  end
end
