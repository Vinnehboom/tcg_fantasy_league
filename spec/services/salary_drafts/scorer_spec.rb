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
      players.each { |player| player.external_scores.destroy_all }
    end

    it 'updates the participation score with the points gained by all roster players since the tournament started' do
      player1, player2 = players
      travel_to 3.days.ago
      create(:external_score, player: player1, score: 20)
      create(:external_score, player: player2, score: 30)
      travel_to 7.days.from_now
      create(:external_score, player: player1, score: 40)
      create(:external_score, player: player2, score: 50)
      described_class.new.score(participation:, draft:)
      expect(participation.reload.score).to eq(40)
    end
  end

end
