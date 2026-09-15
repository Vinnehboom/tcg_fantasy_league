require 'rails_helper'

RSpec.describe Player do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to have_many(:external_scores).through(:player_seasons) }
  it { is_expected.to have_many(:results) }
  it { is_expected.to have_many(:external_requests).dependent(:nullify) }
  it { is_expected.to have_many(:player_seasons).dependent(:destroy) }
  it { is_expected.to have_many(:seasons).through(:player_seasons) }
  it { is_expected.to have_many(:data_subject_requests).dependent(:destroy) }

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

  describe 'the :without_scores factory trait' do
    context 'when the game has no season yet' do
      it 'has no player_seasons' do
        player = create(:player, :without_scores)

        expect(player.player_seasons).to be_empty
      end
    end

    context 'when the game already has a season' do
      let(:game) { create(:game) }
      let(:season) { create(:season, game:) }
      let(:player) { create(:player, :without_scores, game:) }

      before { season }

      it 'joins the existing season' do
        expect(player.reload.seasons).to eq([season])
      end

      it 'has no score' do
        expect(player.external_scores).to be_empty
      end
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

  describe '#record_score!' do
    let(:player) { create(:player, :without_scores) }
    let(:season) { create(:season, game: player.game) }

    def recorded_score_in(season)
      player.reload.player_seasons.find_by(season:)&.latest_score
    end

    context 'when the player has no score yet' do
      it 'creates a snapshot' do
        expect { player.record_score!(score: 100, season:) }.to change(player.external_scores, :count).from(0).to(1)
      end

      it 'lands the score on the given season' do
        player.record_score!(score: 100, season:)

        expect(recorded_score_in(season)).to eq(100)
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

  describe '.not_suppressed' do
    it 'excludes a suppressed player' do
      create(:player, :suppressed, name: 'Hidden Player')

      expect(described_class.not_suppressed).to be_empty
    end

    it 'includes a player who is not suppressed' do
      player = create(:player)

      expect(described_class.not_suppressed).to contain_exactly(player)
    end
  end

  describe '.suppressed' do
    it 'returns only a suppressed player' do
      suppressed_player = create(:player, :suppressed)
      create(:player)

      expect(described_class.suppressed).to contain_exactly(suppressed_player)
    end
  end

  describe 'a plain query, with no explicit suppression scope' do
    it 'includes a suppressed player' do
      suppressed_player = create(:player, :suppressed)

      expect(described_class.all).to contain_exactly(suppressed_player)
    end

    it 'finds a suppressed player by id' do
      suppressed_player = create(:player, :suppressed)

      expect(described_class.find(suppressed_player.id)).to eq(suppressed_player)
    end
  end

  describe '#suppressed?' do
    it 'is true once suppressed_at is set' do
      player = build(:player, suppressed_at: Time.current)

      expect(player).to be_suppressed
    end

    it 'is false when suppressed_at is nil' do
      player = build(:player, suppressed_at: nil)

      expect(player).not_to be_suppressed
    end
  end

  describe '#name' do
    it 'returns the real name for a player who is not suppressed' do
      player = build(:player, name: 'Real Name')

      expect(player.name).to eq('Real Name')
    end

    it 'returns a placeholder for a suppressed player, and never the real name' do
      player = build(:player, name: 'Real Name', suppressed_at: Time.current)

      expect(player.name).to eq(I18n.t('players.suppressed_display_name'))
    end
  end

  describe '#raw_name' do
    it 'returns the real name for a player who is not suppressed' do
      player = build(:player, name: 'Real Name')

      expect(player.raw_name).to eq('Real Name')
    end

    it 'returns the real name for a suppressed player too, unlike #name' do
      player = build(:player, name: 'Real Name', suppressed_at: Time.current)

      expect(player.raw_name).to eq('Real Name')
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
