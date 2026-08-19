require 'rails_helper'

RSpec.describe Player do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to have_many(:external_scores) }
  it { is_expected.to have_many(:results) }
  it { is_expected.to have_many(:external_requests).dependent(:nullify) }

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

  describe '#latest_score' do
    let(:player) { create(:player, :without_scores) }

    context 'when no season is given' do
      it 'returns the most recent score regardless of season' do
        create(:external_score, player:, score: 10, season: 'S1', created_at: 2.days.ago)
        latest = create(:external_score, player:, score: 20, season: 'S2', created_at: 1.day.ago)

        expect(player.reload.latest_score).to eq(latest.score)
      end
    end

    context 'when a season is given' do
      it 'returns the most recent score within that season' do
        create(:external_score, player:, score: 10, season: 'S1', created_at: 2.days.ago)
        latest = create(:external_score, player:, score: 20, season: 'S1', created_at: 1.day.ago)
        create(:external_score, player:, score: 99, season: 'S2', created_at: Time.current)

        expect(player.reload.latest_score(season: 'S1')).to eq(latest.score)
      end

      it 'returns nil when the player has no score in that season' do
        create(:external_score, player:, score: 10, season: 'S1')

        expect(player.reload.latest_score(season: 'S2')).to be_nil
      end
    end
  end

  describe '#record_score!' do
    let(:player) { create(:player, :without_scores) }

    context 'when the player has no score yet' do
      it 'creates a snapshot' do
        expect { player.record_score!(100) }.to change(player.external_scores, :count).from(0).to(1)
      end
    end

    context 'when the new value differs from the most recent score' do
      before { create(:external_score, player:, score: 100) }

      it 'appends a new snapshot' do
        expect { player.record_score!(150) }.to change(player.external_scores, :count).from(1).to(2)
      end
    end

    context 'when the new value matches the most recent score' do
      before { create(:external_score, player:, score: 100) }

      it 'does not append a new snapshot' do
        expect { player.record_score!(100) }.not_to change(player.external_scores, :count)
      end
    end

    context 'when the new value matches but arrives as a different type' do
      before { create(:external_score, player:, score: 100) }

      it 'still recognizes it as unchanged' do
        expect { player.record_score!('100') }.not_to change(player.external_scores, :count)
      end
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
