require 'rails_helper'

RSpec.describe Demo::Curves do
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

  describe '::ACCUMULATING' do
    let(:rng) { Random.new(1) }

    it 'never exceeds the current score, since championship points only accumulate' do
      score = described_class::ACCUMULATING.call(current_score: 1300, fraction: 1.0, range:, rng:)

      expect(score).to be <= 1300
    end

    it 'sits near the bottom of the range at the oldest checkpoint' do
      score = described_class::ACCUMULATING.call(current_score: 1300, fraction: 0.0, range:, rng:)

      expect(score).to be_within(20).of(range.min)
    end
  end

  describe '::WANDERING' do
    it 'returns exactly the current score at the most recent checkpoint, since drift is zeroed there' do
      score = described_class::WANDERING.call(current_score: 1300, fraction: 1.0, range:, rng: Random.new(1))

      expect(score).to eq(1300)
    end

    it 'clamps drift to the score range at the oldest checkpoint' do
      rng = instance_double(Random, rand: described_class::WANDERING_JITTER.max)

      score = described_class::WANDERING.call(current_score: 1590, fraction: 0.0, range:, rng:)

      expect(score).to eq(range.max)
    end
  end
end
