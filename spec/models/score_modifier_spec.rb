require 'rails_helper'

RSpec.describe ScoreModifier do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:value) }
  it { is_expected.to have_many(:player_season_modifiers).dependent(:destroy) }
  it { is_expected.to have_many(:player_seasons).through(:player_season_modifiers) }

  describe '#player_seasons' do
    subject(:player_seasons) { score_modifier.reload.player_seasons }

    let(:score_modifier) { create(:multiplier) }
    let(:player_season) { create(:player_season) }

    before { create(:player_season_modifier, player_season:, score_modifier:) }

    it 'includes a player_season attached through player_season_modifiers' do
      expect(player_seasons).to include(player_season)
    end
  end

  describe '#apply' do
    subject(:apply) { score_modifier.apply(10) }

    let(:score_modifier) { build(:score_modifier) }

    it 'raises NotImplementedError on the base class' do
      expect { apply }.to raise_error(NotImplementedError)
    end
  end
end
