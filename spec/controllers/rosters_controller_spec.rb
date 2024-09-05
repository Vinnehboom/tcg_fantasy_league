require 'rails_helper'

RSpec.describe RostersController do
  let(:game) { create(:game, id: 'PTCG') }
  let(:user) { create(:user) }
  let(:participation) { create(:participation, user:) }

  describe '#edit' do
    let(:roster) { create(:roster, participation:) }

    before do
      sign_in user
    end

    it 'applies the cost to all available players' do
      player1, player2 = create_list(:player, 2, :without_scores, game:)
      player1.external_scores.create(score: 50)
      player2.external_scores.create(score: 200)
      get :edit, params: { id: roster.id, game: game.id }
      expect(assigns(:players).map(&:cost)).to include(10.0, 25.0)
    end

    context 'when filtering the players' do
      context 'when filtering for country'  do
        it 'shows only the country specific players' do
          player1, player2 = create_list(:player, 2, game:, country: 'BE')
          player3 = create(:player, game:, country: 'FR')
          get :edit, params: { id: roster.id, game: game.id, country: 'BE' }
          expect(assigns(:players)).to include(player1, player2)
          expect(assigns(:players)).not_to include(player3)
        end
      end

      context 'when filtering for name' do
        it 'shows only the players with a like name' do
          player1 = create(:player, game:, name: 'Sen')
          player2 = create(:player, game:, name: 'Pedersen')
          player3 = create(:player, game:, name: 'Karel')
          get :edit, params: { id: roster.id, game: game.id, name: 'sen' }
          expect(assigns(:players)).to include(player1, player2)
          expect(assigns(:players)).not_to include(player3)
        end
      end
    end
  end
end
