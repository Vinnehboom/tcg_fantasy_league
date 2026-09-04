require 'rails_helper'

RSpec.describe ExternalData::Synthetic::ScoreCurves do
  let(:range) { (1000..1600) }
  let(:count) { 20 }

  describe '::LADDER' do
    it 'gives rank 0 (the top) the highest score in the field' do
      top = described_class::LADDER.call(index: 0, count:, range:)
      bottom = described_class::LADDER.call(index: count - 1, count:, range:)

      expect(top).to be > bottom
    end
  end

  describe '::ELO_BAND' do
    it 'gives rank 0 (the top) the highest score in the field, same convention as LADDER' do
      top = described_class::ELO_BAND.call(index: 0, count:, range:)
      bottom = described_class::ELO_BAND.call(index: count - 1, count:, range:)

      expect(top).to be > bottom
    end

    it 'does not raise for a one-player field' do
      expect { described_class::ELO_BAND.call(index: 0, count: 1, range:) }.not_to raise_error
    end

    it 'returns the midpoint of the range for a one-player field' do
      midpoint = (range.min + range.max) / 2.0

      expect(described_class::ELO_BAND.call(index: 0, count: 1, range:)).to eq(midpoint)
    end
  end
end
