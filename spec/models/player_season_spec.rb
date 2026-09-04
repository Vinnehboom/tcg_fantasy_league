require 'rails_helper'

RSpec.describe PlayerSeason do
  it { is_expected.to belong_to(:player) }
  it { is_expected.to belong_to(:season) }
  it { is_expected.to have_many(:external_scores).dependent(:destroy) }
  it { is_expected.to have_many(:player_season_modifiers).dependent(:destroy) }
  it { is_expected.to have_many(:score_modifiers).through(:player_season_modifiers) }

  describe '#score_modifiers' do
    subject(:score_modifiers) { player_season.reload.score_modifiers }

    let(:player_season) { create(:player_season) }
    let(:score_modifier) { create(:multiplier) }

    before { create(:player_season_modifier, player_season:, score_modifier:) }

    it 'includes a modifier attached to the player season' do
      expect(score_modifiers).to include(score_modifier)
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
