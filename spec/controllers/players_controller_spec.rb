require 'rails_helper'

RSpec.describe PlayersController do
  let(:game) { create(:game, name: 'PTCG') }

  describe '#index' do
    it 'sorts the players by their highest external score' do
      player1, player2, player3 = create_list(:player, 3, game:)
      player1.external_scores.create(score: 1000)
      player2.external_scores.create(score: 900)
      player3.external_scores.create(score: 1200)
      get :index, params: { game: game.name }
      expect(assigns(:players).to_a).to eq([player3, player1, player2])
    end
  end
end
