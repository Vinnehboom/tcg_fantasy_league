require 'rails_helper'

RSpec.describe PlayerSeasonModifier do
  it { is_expected.to belong_to(:player_season) }
  it { is_expected.to belong_to(:score_modifier) }

  describe 'uniqueness' do
    subject { build(:player_season_modifier, player_season:, score_modifier:).save }

    let(:player_season) { create(:player_season) }
    let(:score_modifier) { create(:multiplier) }

    context 'when the player does not have this modifier for the season yet' do
      it { is_expected.to be_truthy }
    end

    context 'when the player already has a different modifier for the season' do
      before do
        create(:player_season_modifier, player_season:, score_modifier: create(:bonus))
      end

      it { is_expected.to be_truthy }
    end

    context 'when a different player already has this modifier for their season' do
      before do
        create(:player_season_modifier, player_season: create(:player_season), score_modifier:)
      end

      it { is_expected.to be_truthy }
    end

    context 'when the player already has this exact modifier for the season' do
      before do
        create(:player_season_modifier, player_season:, score_modifier:)
      end

      it { is_expected.to be_falsey }
    end
  end
end
