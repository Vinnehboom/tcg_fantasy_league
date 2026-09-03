require 'rails_helper'

module Scoring

  RSpec.describe Strategy do
    subject(:strategy) { described_class.new }

    # Duck-typed fixtures for #points_for's `result:` argument — a local
    # Struct rather than a double/OpenStruct, per the style guide.
    let(:tournament_fixture) { Struct.new(:field_size) }
    let(:result_fixture) { Struct.new(:placement, :tournament) }

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

    describe '#points_for' do
      subject(:points_for) do
        strategy.points_for(result: result_fixture.new(placement, tournament_fixture.new(field_size)))
      end

      context 'with the worked 3000-player (XL) example' do
        let(:field_size) { 3000 }

        where(:placement, :expected_points) do
          [
            [1, 800],
            [2, 520],
            [4, 336],
            [8, 216],
            [64, 64],
            [512, 16],
            [1024, 8],
            [2500, 8] # missed the deepest real bracket (max_tier 2048)
          ]
        end

        with_them do
          it { is_expected.to eq(expected_points) }
        end
      end

      context 'with a small (S) field' do
        let(:placement) { 1 }
        let(:field_size) { 100 }

        it 'applies the S multiplier (x1), not XL' do
          expect(points_for).to eq(100)
        end
      end

      context 'when the tournament has no field_size on record' do
        let(:placement) { 1 }
        let(:field_size) { nil }

        it 'raises MissingFieldSizeError' do
          expect { points_for }.to raise_error(Scoring::MissingFieldSizeError)
        end
      end
    end
  end

end
