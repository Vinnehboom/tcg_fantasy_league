require 'rails_helper'

RSpec.describe Player do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to have_many(:external_scores).through(:player_seasons) }
  it { is_expected.to have_many(:results) }
  it { is_expected.to have_many(:external_requests).dependent(:nullify) }
  it { is_expected.to have_many(:player_seasons).dependent(:destroy) }
  it { is_expected.to have_many(:seasons).through(:player_seasons) }

  it { is_expected.to belong_to(:game) }

  describe '#seasons' do
    subject(:seasons) { player.reload.seasons }

    let(:player) { create(:player) }
    let(:season) { create(:season) }

    before { create(:player_season, player:, season:) }

    it 'includes a season the player has joined through player_seasons' do
      expect(seasons).to include(season)
    end
  end

  describe '#external_scores' do
    subject(:external_scores) { player.reload.external_scores }

    let(:player) { create(:player, :without_scores) }
    let(:player_season) { create(:player_season, player:, season: create(:season, game: player.game)) }
    let(:external_score) { create(:external_score, player_season:) }

    before { external_score }

    it 'includes a score reached through the player\'s player_seasons' do
      expect(external_scores).to include(external_score)
    end
  end

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
    let(:season_one) do
      create(:season, game: player.game, label: 'S1', start_date: 2.years.ago, end_date: 13.months.ago)
    end
    let(:season_two) { create(:season, game: player.game, label: 'S2', start_date: 1.year.ago, end_date: nil) }
    let(:player_season_one) { create(:player_season, player:, season: season_one) }
    let(:player_season_two) { create(:player_season, player:, season: season_two) }

    context 'when no season is given' do
      it 'returns the most recent score regardless of season' do
        create(:external_score, player_season: player_season_one, score: 10, created_at: 2.days.ago)
        latest = create(:external_score, player_season: player_season_two, score: 20, created_at: 1.day.ago)

        expect(player.reload.latest_score).to eq(latest.score)
      end
    end

    context 'when a season is given' do
      it 'returns the most recent score within that season' do
        create(:external_score, player_season: player_season_one, score: 10, created_at: 2.days.ago)
        latest = create(:external_score, player_season: player_season_one, score: 20, created_at: 1.day.ago)
        create(:external_score, player_season: player_season_two, score: 99, created_at: Time.current)

        expect(player.reload.latest_score(season: season_one)).to eq(latest.score)
      end

      it 'returns nil when the player has no score in that season' do
        create(:external_score, player_season: player_season_one, score: 10)

        expect(player.reload.latest_score(season: season_two)).to be_nil
      end
    end
  end

  describe '#record_score!' do
    let(:player) { create(:player, :without_scores) }
    let(:season) { create(:season, game: player.game) }

    context 'when the player has no score yet' do
      it 'creates a snapshot' do
        expect { player.record_score!(score: 100, season:) }.to change(player.external_scores, :count).from(0).to(1)
      end

      it 'lands the score on the given season' do
        player.record_score!(score: 100, season:)

        expect(player.reload.latest_score(season:)).to eq(100)
      end
    end

    context 'when the new value differs from the most recent score' do
      before { player.record_score!(score: 100, season:) }

      it 'appends a new snapshot' do
        expect { player.record_score!(score: 150, season:) }.to change(player.external_scores, :count).from(1).to(2)
      end
    end

    context 'when the new value matches the most recent score' do
      before { player.record_score!(score: 100, season:) }

      it 'does not append a new snapshot' do
        expect { player.record_score!(score: 100, season:) }.not_to change(player.external_scores, :count)
      end
    end

    context 'when the new value matches but arrives as a different type' do
      before { player.record_score!(score: 100, season:) }

      it 'still recognizes it as unchanged' do
        expect { player.record_score!(score: '100', season:) }.not_to change(player.external_scores, :count)
      end
    end

    context 'when called for a different season with the same score as the last one' do
      let(:other_season) do
        create(:season, game: player.game, start_date: 2.years.ago, end_date: 13.months.ago)
      end

      before { player.record_score!(score: 100, season: other_season) }

      it 'still joins the player to the new season' do
        expect { player.record_score!(score: 100, season:) }.to change { player.reload.seasons.count }.from(1).to(2)
      end

      it 'still creates a snapshot for the new season' do
        expect { player.record_score!(score: 100, season:) }.to change(player.external_scores, :count).from(1).to(2)
      end
    end

    context 'when called twice for the same season' do
      it 'reuses the existing player_season instead of creating a second one' do
        player.record_score!(score: 100, season:)

        expect { player.record_score!(score: 150, season:) }.not_to(change { player.reload.player_seasons.count })
      end
    end
  end

  describe '#external_url' do
    let(:game) { create(:game, base_uri: 'https://limitlesstcg.com') }
    let(:player) { create(:player, :without_scores, game:, external_id: '/players/370') }

    context "when a Season covers the current date for the player's game" do
      before { create(:season, game:, label: '2026', start_date: 1.month.ago, end_date: 1.month.from_now) }

      it "appends the season param to the game's base_uri URL" do
        expect(player.external_url).to eq('https://limitlesstcg.com/players/370?season=2026')
      end
    end

    context "when no Season covers the current date for the player's game" do
      it 'falls back to the plain game base_uri URL' do
        expect(player.external_url).to eq('https://limitlesstcg.com/players/370')
      end
    end

    context 'when a Season covers the current date, but only for a different game' do
      before do
        other_game = create(:game)
        create(:season, game: other_game, label: '2026', start_date: 1.month.ago, end_date: 1.month.from_now)
      end

      it 'falls back to the plain game base_uri URL' do
        expect(player.external_url).to eq('https://limitlesstcg.com/players/370')
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
      player.player_seasons.destroy_all
      travel 5.days
      create(:external_score, player:, score: 40).score
      player.reload
      expect(player.score_difference(date: 1.day.from_now, other_date: 1.day.ago)).to eq(40)
    end
  end
end
