require 'rails_helper'

RSpec.describe Multiplier do
  describe '#apply' do
    subject(:apply) { multiplier.apply(10) }

    let(:multiplier) { build(:multiplier, value: 1.5) }

    it 'multiplies the score by value' do
      expect(apply).to eq(15)
    end
  end
end
