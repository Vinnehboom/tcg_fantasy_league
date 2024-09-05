require 'rails_helper'

RSpec.describe RosterPlayer do
  it { is_expected.to belong_to(:roster) }
  it { is_expected.to belong_to(:player) }

  describe '#player_cost' do
    let(:player) { create(:player, :without_scores) }
    let(:draft) { create(:salary_draft) }
    let(:participation) { create(:participation, draft:) }
    let(:roster) { create(:roster, participation:) }
    let(:roster_player) { create(:roster_player, player:, roster:) }

    it "reflects the player's cost for the roster's draft" do
      create(:external_score, player:, score: 500)
      expect(roster_player.player_cost).to eq(40.0)
    end
  end
end
