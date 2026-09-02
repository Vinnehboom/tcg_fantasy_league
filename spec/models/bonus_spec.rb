require 'rails_helper'

RSpec.describe Bonus do
  describe '#apply' do
    subject(:apply) { bonus.apply(10) }

    let(:bonus) { build(:bonus, value: 5) }

    it 'adds value to the score' do
      expect(apply).to eq(15)
    end
  end
end
