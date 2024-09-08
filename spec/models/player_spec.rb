require 'rails_helper'

RSpec.describe Player do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to have_many(:external_scores) }

  it { is_expected.to belong_to(:game) }

  describe '#current_score' do
    let(:player) { create(:player) }

    it 'reflects the most recent score for the player' do
      old_score = player.current_score
      create(:external_score, player:)
      current_score = player.reload.current_score
      expect(current_score).not_to eq(old_score)
    end
  end

  describe '#latest_score_before' do
    let(:player) { create(:player) }

    it 'reflects the most recent score for the player before the given date' do
      player.current_score
      date = 5.days.ago
      latest_score = create(:external_score, player:, created_at: 10.days.ago)
      player.reload
      expect(player.latest_score_before(date:)).to eq(latest_score.score)
    end
  end

  describe '#score_difference' do
    let(:player) { create(:player) }

    it 'shows the difference in scores before the given dates' do
      create(:external_score, player:, score: 20).score
      travel 5.days
      create(:external_score, player:, score: 40).score
      player.reload
      expect(player.score_difference(date: 1.day.from_now, other_date: 1.day.ago)).to eq(20)
    end

    it 'works with dates where the player did not have a score' do
      player.external_scores.destroy_all
      travel 5.days
      create(:external_score, player:, score: 40).score
      player.reload
      expect(player.score_difference(date: 1.day.from_now, other_date: 1.day.ago)).to eq(40)
    end
  end
end
