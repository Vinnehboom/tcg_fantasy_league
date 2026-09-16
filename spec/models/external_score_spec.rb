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

  describe '.latest_per_player_season' do
    subject(:rows) { described_class.latest_per_player_season(player_seasons.map(&:id)).to_a }

    let(:player) { create(:player, :without_scores) }
    let(:season_one) do
      create(:season, game: player.game, label: 'S1', start_date: 2.years.ago, end_date: 13.months.ago)
    end
    let(:season_two) { create(:season, game: player.game, label: 'S2', start_date: 1.year.ago, end_date: nil) }
    let(:player_season_one) { create(:player_season, player:, season: season_one) }
    let(:player_season_two) { create(:player_season, player:, season: season_two) }
    let(:player_seasons) { [player_season_one, player_season_two] }

    def score_for(player_season)
      rows.find { |row| row.player_season_id == player_season.id }&.score
    end

    context 'when a player season holds several scores' do
      before do
        create(:external_score, player_season: player_season_one, score: 10, created_at: 3.days.ago)
        create(:external_score, player_season: player_season_one, score: 30, created_at: 1.day.ago)
      end

      it 'returns one row for that player season' do
        expect(rows.count { |row| row.player_season_id == player_season_one.id }).to eq(1)
      end

      it 'returns the most recent score' do
        expect(score_for(player_season_one)).to eq(30)
      end
    end

    context 'when two seasons of the same player each hold a score' do
      before do
        create(:external_score, player_season: player_season_one, score: 10)
        create(:external_score, player_season: player_season_two, score: 20)
      end

      it 'keeps the score of each season apart' do
        expect([score_for(player_season_one), score_for(player_season_two)]).to eq([10, 20])
      end
    end

    context 'when a player season holds no score' do
      before { create(:external_score, player_season: player_season_one, score: 10) }

      it 'returns no row for that player season' do
        expect(score_for(player_season_two)).to be_nil
      end
    end

    context 'when two scores of one player season hold the same time' do
      before do
        create(:external_score, player_season: player_season_one, score: 10, created_at: 1.day.ago)
        create(:external_score, player_season: player_season_one, score: 40, created_at: 1.day.ago)
      end

      it 'keeps the score that was recorded last' do
        expect(score_for(player_season_one)).to eq(40)
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
