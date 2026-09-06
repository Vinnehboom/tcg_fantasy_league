require 'rails_helper'

RSpec.describe 'Players' do
  let(:game) { create(:game, id: 'PTCG') }

  describe '#index' do
    it 'shows all players' do
      get game_players_path(game: game.id)

      expect(response).to render_template('players/index')
    end

    context 'when a player has no country' do
      let(:known_country) { create(:player, game:, country: 'JP') }
      let(:blank_country) { create(:player, game:, country: nil) }

      before do
        known_country
        blank_country
      end

      it 'still shows the page' do
        get game_players_path(game: game.id)

        expect(response).to render_template('players/index')
      end

      it 'leaves the missing country out of the country filter' do
        get game_players_path(game: game.id)

        expect(assigns(:countries)).to eq(['JP'])
      end
    end
  end
end
