require 'rails_helper'

RSpec.describe ScoreModifier do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:value) }

  describe '#apply' do
    subject(:apply) { score_modifier.apply(10) }

    let(:score_modifier) { build(:score_modifier) }

    it 'raises NotImplementedError on the base class' do
      expect { apply }.to raise_error(NotImplementedError)
    end
  end
end
