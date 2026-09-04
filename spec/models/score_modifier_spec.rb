require 'rails_helper'

RSpec.describe ScoreModifier do
  it { is_expected.to validate_inclusion_of(:name).in_array(described_class.names.values) }
  it { is_expected.to validate_presence_of(:value) }
  it { is_expected.to have_many(:player_season_modifiers).dependent(:destroy) }
  it { is_expected.to have_many(:player_seasons).through(:player_season_modifiers) }

  describe '#player_seasons' do
    subject(:player_seasons) { score_modifier.reload.player_seasons }

    let(:score_modifier) { create(:multiplier) }
    let(:player_season) { create(:player_season) }

    before { create(:player_season_modifier, player_season:, score_modifier:) }

    it 'includes a player_season attached to the modifier' do
      expect(player_seasons).to include(player_season)
    end
  end

  describe '#apply' do
    subject(:apply) { score_modifier.apply(10) }

    context 'when called on the base class' do
      let(:score_modifier) { build(:score_modifier) }

      it 'raises NotImplementedError' do
        expect { apply }.to raise_error(NotImplementedError)
      end
    end
  end

  describe 'validation of the kind of modifier' do
    it 'accepts a multiplier' do
      expect(build(:multiplier)).to be_valid
    end

    it 'accepts a bonus' do
      expect(build(:bonus)).to be_valid
    end

    it 'rejects a modifier with no kind' do
      expect(build(:score_modifier)).not_to be_valid
    end
  end

  describe 'validation of the value' do
    it 'rejects a value that is not a number' do
      expect(build(:bonus, value: 'free points')).not_to be_valid
    end

    it 'accepts a bonus that takes points away' do
      expect(build(:bonus, value: -5)).to be_valid
    end
  end

  describe 'the :any_subtype factory trait' do
    subject(:score_modifier) { create(:score_modifier, :any_subtype) }

    it 'persists' do
      expect(score_modifier).to be_persisted
    end

    it 'builds a concrete subtype' do
      expect(score_modifier.class).to be_in([Multiplier, Bonus])
    end
  end

  describe 'the .kept scope' do
    subject(:kept_modifiers) { described_class.kept }

    let(:kept_modifier) { create(:multiplier) }
    let(:discarded_modifier) { create(:bonus, discarded_at: Time.current) }

    before do
      kept_modifier
      discarded_modifier
    end

    it { is_expected.to contain_exactly(kept_modifier) }
  end

  describe 'a plain lookup' do
    it 'still resolves a discarded modifier - there is no default_scope to opt out of' do
      score_modifier = create(:multiplier, discarded_at: Time.current)

      expect(described_class.find_by(id: score_modifier.id)).to eq(score_modifier)
    end
  end
end
