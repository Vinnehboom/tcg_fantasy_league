require 'rails_helper'

RSpec.describe ExternalScore do
  it { is_expected.to belong_to(:player_season) }
  it { is_expected.to have_one(:player).through(:player_season) }

  describe '.latest_per_player' do
    subject(:rows) { described_class.latest_per_player.to_a }

    let(:player) { create(:player, :without_scores) }
    let(:latest_created_at) { 1.day.ago }

    before do
      create(:external_score, player:, score: 10, created_at: 3.days.ago)
      create(:external_score, player:, score: 20, created_at: 2.days.ago)
      create(:external_score, player:, score: 30, created_at: latest_created_at)
    end

    it 'returns one row for a player with several scores' do
      expect(rows.count { |row| row.player_id == player.id }).to eq(1)
    end

    it 'returns the most recent score of the player' do
      expect(rows.find { |row| row.player_id == player.id }.score).to eq(30)
    end

    context 'when a second player also holds a score' do
      let(:other_player) { create(:player, :without_scores) }

      before do
        create(:external_score, player: other_player, score: 99)
      end

      it 'returns a row for each player' do
        expect(rows.map(&:player_id)).to contain_exactly(player.id, other_player.id)
      end
    end

    context 'when two scores of the player hold the same time' do
      before do
        create(:external_score, player:, score: 40, created_at: latest_created_at)
      end

      it 'keeps the score that was recorded last' do
        expect(rows.find { |row| row.player_id == player.id }.score).to eq(40)
      end
    end
  end

  describe 'score validation' do
    subject(:save) { build(:external_score, player:, score:).save }

    let(:player) { create(:player) }
    let(:score) { 20 }

    context 'when score is present' do
      it { expect(save).to be_truthy }
    end

    context 'when score is missing' do
      let(:score) { nil }

      it { expect(save).to be_falsey }
    end

    context 'when the player already has a snapshot with the same score' do
      before do
        create(:external_score, player:, score:)
      end

      it 'allows the repeated snapshot' do
        expect(save).to be_truthy
      end
    end
  end
end
