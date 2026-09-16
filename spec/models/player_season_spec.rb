require 'rails_helper'

RSpec.describe PlayerSeason do
  it { is_expected.to belong_to(:player) }
  it { is_expected.to belong_to(:season) }
  it { is_expected.to have_many(:external_scores).dependent(:destroy) }
  it { is_expected.to have_many(:player_season_modifiers).dependent(:destroy) }
  it { is_expected.to have_many(:score_modifiers).through(:player_season_modifiers) }

  describe '#player, when the player is suppressed' do
    it 'still resolves to the player instead of nil' do
      player = create(:player, :suppressed)
      player_season = create(:player_season, player:)

      expect(player_season.reload.player).to eq(player)
    end
  end

  describe '#score_modifiers' do
    subject(:score_modifiers) { player_season.reload.score_modifiers }

    let(:player_season) { create(:player_season) }
    let(:score_modifier) { create(:multiplier) }

    before { create(:player_season_modifier, player_season:, score_modifier:) }

    it 'includes a modifier attached to the player season' do
      expect(score_modifiers).to include(score_modifier)
    end
  end

  describe '#latest_score' do
    let(:player_season) { create(:player_season) }

    def add_score(score, created_at: Time.current)
      create(:external_score, player_season:, score:, created_at:)
    end

    context 'when the player season holds no score' do
      it 'is nil' do
        expect(player_season.latest_score).to be_nil
      end
    end

    context 'when the player season holds several scores' do
      it 'returns the most recent one' do
        add_score(10, created_at: 2.days.ago)
        add_score(30, created_at: 1.day.ago)

        expect(player_season.latest_score).to eq(30)
      end
    end

    context 'when two scores hold the same time' do
      it 'returns the one that was recorded last' do
        same_time = 1.day.ago
        add_score(10, created_at: same_time)
        add_score(40, created_at: same_time)

        expect(player_season.latest_score).to eq(40)
      end
    end

    context 'when a caller has supplied the value' do
      it 'answers with that value and reads no score row' do
        add_score(10)
        player_season.latest_score = 99

        expect(count_queries(pattern: /FROM "external_scores"/) { player_season.latest_score }).to eq(0)
        expect(player_season.latest_score).to eq(99)
      end
    end

    context 'when the player season is reloaded after a caller supplied a value' do
      it 'answers from the score rows again, not from the supplied value' do
        add_score(10)
        player_season.latest_score = 99

        player_season.reload

        expect(player_season.latest_score).to eq(10)
      end
    end

    context 'when a caller has supplied nil' do
      it 'treats the player season as having no score, and reads no score row' do
        add_score(10)
        player_season.latest_score = nil

        expect(count_queries(pattern: /FROM "external_scores"/) { player_season.latest_score }).to eq(0)
        expect(player_season.latest_score).to be_nil
      end
    end
  end

  describe '#record_score!' do
    let(:player_season) { create(:player_season) }

    context 'when the player season holds no score yet' do
      it 'appends a snapshot' do
        expect { player_season.record_score!(score: 100) }.to change(player_season.external_scores, :count).by(1)
      end
    end

    context 'when the new value differs from the most recent score' do
      before { player_season.record_score!(score: 100) }

      it 'appends a snapshot' do
        expect { player_season.record_score!(score: 150) }.to change(player_season.external_scores, :count).by(1)
      end
    end

    context 'when the new value matches the most recent score' do
      before { player_season.record_score!(score: 100) }

      it 'appends no snapshot' do
        expect { player_season.record_score!(score: 100) }.not_to change(player_season.external_scores, :count)
      end
    end

    context 'when the new value matches but arrives as a string' do
      before { player_season.record_score!(score: 100) }

      it 'still counts as unchanged' do
        expect { player_season.record_score!(score: '100') }.not_to change(player_season.external_scores, :count)
      end
    end

    context 'when a caller has supplied the most recent score' do
      it 'appends no snapshot for a value that matches it' do
        player_season.latest_score = 100

        expect { player_season.record_score!(score: 100) }.not_to change(player_season.external_scores, :count)
      end

      it 'appends a snapshot for a value that differs from it' do
        player_season.latest_score = 100

        expect { player_season.record_score!(score: 150) }.to change(player_season.external_scores, :count).by(1)
      end
    end
  end

  describe 'uniqueness' do
    subject { build(:player_season, player:, season:).save }

    let(:player) { create(:player) }
    let(:season) { create(:season) }

    context 'when the player does not have a player_season in the season' do
      it { is_expected.to be_truthy }
    end

    context 'when another player has a player_season in the season' do
      before do
        create(:player_season, player: create(:player), season:)
      end

      it { is_expected.to be_truthy }
    end

    context 'when the player already has a player_season in a different season' do
      before do
        create(:player_season, player:, season: create(:season))
      end

      it { is_expected.to be_truthy }
    end

    context 'when the player already has a player_season in the season' do
      before do
        create(:player_season, player:, season:)
      end

      it { is_expected.to be_falsey }
    end
  end
end
