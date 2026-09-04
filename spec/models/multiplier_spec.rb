require 'rails_helper'

RSpec.describe Multiplier do
  describe '#apply' do
    subject(:apply) { multiplier.apply(10) }

    let(:multiplier) { build(:multiplier, value: 1.5) }

    it 'multiplies the score by value' do
      expect(apply).to eq(15)
    end
  end

  describe 'validation of the value' do
    it 'rejects a multiplier that wipes out the score' do
      expect(build(:multiplier, value: 0)).not_to be_valid
    end

    it 'rejects a multiplier that reverses the score' do
      expect(build(:multiplier, value: -2)).not_to be_valid
    end

    it 'reports a missing value once, not once per numericality check' do
      multiplier = build(:multiplier, value: nil)

      multiplier.valid?

      expect(multiplier.errors.of_kind?(:value, :not_a_number)).to be(true)
      expect(multiplier.errors.where(:value, :not_a_number).size).to eq(1)
    end
  end
end
