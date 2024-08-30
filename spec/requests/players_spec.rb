require 'rails_helper'

RSpec.describe 'Players' do
  let!(:game) { create(:game, id: 'PTCG') }

  describe '#index' do
    it 'shows all players' do
      get game_players_path(game: game.id)
      expect(response).to render_template('players/index')
    end
  end
end
