require 'rails_helper'

module Scoring

  RSpec.describe Strategy do
    subject(:strategy) { described_class.new }

    describe '#base_score' do
      context 'with the worked 3000-player (XL) example' do
        where(:placement, :expected_base_score) do
          [
            [1, 100],
            [2, 65],
            [4, 42],
            [8, 27],
            [64, 8],
            [512, 2],
            [1024, 1],
            [2500, 1] # missed the deepest real bracket (max_tier 2048)
          ]
        end

        with_them do
          it { expect(strategy.base_score(placement:, field_size: 3000)).to eq(expected_base_score) }
        end
      end

      context 'when placement is not numerically valid yet (no C-12 validation)' do
        where(:placement, :expected_base_score) do
          [
            [0, 100],
            [-5, 100]
          ]
        end

        with_them do
          it 'clamps to 1st-place tier rather than raising' do
            expect(strategy.base_score(placement:, field_size: 3000)).to eq(expected_base_score)
          end
        end
      end

      context 'when the tournament has no field_size on record' do
        it 'raises MissingFieldSizeError' do
          expect { strategy.base_score(placement: 1, field_size: nil) }
            .to raise_error(Scoring::MissingFieldSizeError)
        end
      end
    end
  end

end
