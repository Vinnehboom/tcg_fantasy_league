require 'rails_helper'

RSpec.describe Roster do
  it { is_expected.to belong_to(:participation) }
  it { is_expected.to have_one(:draft) }
  it { is_expected.to have_one(:tournament) }
  it { is_expected.to have_many(:roster_players) }
  it { is_expected.to have_many(:players) }

  describe '#total_cost' do
    let(:draft) { create(:salary_draft) }
    let(:participation) { create(:participation, draft:) }
    let(:roster) { create(:roster, participation:) }
    let(:visible_player) { create(:player, :without_scores) }
    let(:suppressed_player) { create(:player, :without_scores, :suppressed) }

    before do
      create(:external_score, player: visible_player, score: 500)
      create(:external_score, player: suppressed_player, score: 500)
      create(:roster_player, player: visible_player, roster:)
      create(:roster_player, player: suppressed_player, roster:)
    end

    it 'excludes a suppressed roster_player\'s cost from the total' do
      expect(roster.total_cost).to eq(40.0)
    end
  end

  describe '#roster_size validation' do
    subject { roster }

    let(:roster_size) { 2 }
    let(:roster) { create(:roster, participation: create(:participation, draft: create(:salary_draft, roster_size:))) }

    context 'when the roster is not full' do
      before do
        roster.roster_players.new(player: create(:player))
      end

      it { is_expected.to be_valid }
    end

    context 'when the roster is full' do
      before do
        create_list(:roster_player, roster_size, roster:)
        roster.reload
        roster.roster_players.new(player: create(:player))
      end

      it { is_expected.not_to be_valid }
    end
  end
end
