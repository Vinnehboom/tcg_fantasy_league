require 'rails_helper'

RSpec.describe SalaryDraft do
  it { is_expected.to validate_presence_of(:roster_size) }
  it { is_expected.to validate_presence_of(:price_cap) }
  it { is_expected.to belong_to(:tournament) }
  it { is_expected.to have_many(:participations) }

  describe '#cost_for' do
    let(:player) { create(:player, :without_scores) }
    let(:draft) { create(:salary_draft) }

    it 'reflects the cost for the player for the related tournament' do
      create(:external_score, player:, score: 500)
      expect(draft.cost_for(player:)).to eq(40.0)
    end
  end

  describe '#score_for' do
    let(:draft) { create(:salary_draft) }

    it 'reflects the score for the given cost' do
      expect(draft.score_for(cost: 10)).to eq(50.0)
    end
  end

  describe '.upcoming' do
    subject { described_class.upcoming }

    let(:passed_draft) { create(:salary_draft, tournament: create(:tournament, starting_date: 1.day.ago)) }
    let(:upcoming_draft) { create(:salary_draft, tournament: create(:tournament, starting_date: 1.day.from_now)) }

    it { is_expected.to include(upcoming_draft) }
    it { is_expected.not_to include(passed_draft) }
  end
end
