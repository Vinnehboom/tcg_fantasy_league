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

    it 'shows players for the tournament region first' do
      participation.draft.tournament.update(country: 'DE')
      player1 = create(:player, game:, country: 'US')
      player2 = create(:player, game:, country: 'AU')
      player3 = create(:player, game:, country: 'CZ')
      player4 = create(:player, game:, country: 'ES')
      get :edit, params: { id: roster.id, game: game.id }
      expect(assigns(:players).first(2)).to include(player3, player4)
      expect(assigns(:players).last(2)).to include(player1, player2)
    end

    it 'does not show players the user has already drafted' do
      azul = create(:player, game:, country: 'US')
      create(:player, game:, country: 'NO')
      roster.players << azul
      roster.reload
      get :edit, params: { id: roster.id, game: game.id }
      expect(assigns(:players)).not_to include(azul)
    end

    where(:price_cap, :score1, :score2) do
      [
        [60, 1000, 1000],
        [40, 900, 500],
        [20, 250, 300]
      ]
    end

    with_them do
      it 'does not show players the user cannot afford anymore' do
        participation.draft.update(price_cap:)
        azul = create(:player, game:, country: 'US')
        create(:external_score, player: azul, score: score1)
        tord = create(:player, game:, country: 'NO')
        create(:external_score, player: tord, score: score2)
        roster.players << azul
        roster.reload
        get :edit, params: { id: roster.id, game: game.id }
        expect(assigns(:players)).not_to include(tord)
      end
    end

    it 'sorts the player by highest score within their region' do
      participation.draft.tournament.update(country: 'DE')
      create(:player, game:, country: 'US')
      player3 = create(:player, game:, country: 'CZ')
      player4 = create(:player, game:, country: 'ES')
      player3.external_scores.destroy_all
      player4.external_scores.destroy_all
      create(:external_score, player: player4, score: 1000)
      create(:external_score, player: player3, score: 200)
      get :edit, params: { id: roster.id, game: game.id }
      expect(assigns(:players).first(2)).to eq([player4, player3])
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
