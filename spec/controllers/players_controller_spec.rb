require 'rails_helper'

RSpec.describe PlayersController do
  let(:game) { create(:game, id: 'PTCG') }

  describe '#index' do
    it 'sorts the players by their highest external score' do
      player1, player2, player3 = create_list(:player, 3, game:)
      create(:external_score, player: player1, score: 1000)
      create(:external_score, player: player2, score: 900)
      create(:external_score, player: player3, score: 1200)
      get :index, params: { game: game.id }
      expect(assigns(:players).to_a).to eq([player3, player1, player2])
    end
  end
end
