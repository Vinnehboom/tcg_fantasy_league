require 'rails_helper'

module SalaryDrafts

  RSpec.describe Scorer do
    let(:tournament) { create(:tournament, starting_date: 2.days.ago) }
    let(:draft) { create(:salary_draft, tournament:) }
    let(:participation) { create(:participation, draft:) }
    let(:roster) { create(:roster, participation:) }
    let(:players) { create_list(:player, 2) }

    before do
      roster.players << players
      players.each { |player| player.player_seasons.destroy_all }
    end

    it 'updates the participation score with the points gained by all roster players since the tournament started' do
      player1, player2 = players
      travel_to 3.days.ago
      create(:external_score, player: player1, score: 20)
      create(:external_score, player: player2, score: 30)
      travel_to 7.days.from_now
      create(:external_score, player: player1, score: 40)
      create(:external_score, player: player2, score: 50)
      described_class.call(participation:, draft:)
      expect(participation.reload.score).to eq(40)
    end

    describe 'when a roster player is suppressed' do
      let(:suppressed_player) { create(:player, :without_scores, :suppressed) }

      before { roster.players << suppressed_player }

      it 'does not count that player toward the participation score' do
        travel_to 3.days.ago
        create(:external_score, player: suppressed_player, score: 20)
        travel_to 7.days.from_now
        create(:external_score, player: suppressed_player, score: 1_000)

        described_class.call(participation:, draft:)

        expect(participation.reload.score).to eq(0)
      end

      it 'leaves that roster_player\'s own score untouched' do
        roster_player = RosterPlayer.find_by(roster:, player: suppressed_player)

        expect { described_class.call(participation:, draft:) }.not_to(change { roster_player.reload.score })
      end
    end
  end

end
