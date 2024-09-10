require 'rails_helper'

module Players

  RSpec.describe ScoreCalculator do
    describe '#calculate_score' do
      where(:price_rules, :cost, :expected_score) do
        [
          [[], 0.0, 0.0],
          [[ScalingPriceRule.new], 10, 50],
          [[ScalingPriceRule.new], 30, 300.0],
          [[ScalingPriceRule.new], 80, 2300.0],
          [[ScalingPriceRule.new(scales: [
                                   {
                                     minimum_cost: 0,
                                     maximum_cost: 20,
                                     point_coefficient: 2.00
                                   }
                                 ])], 10, 20.0]
        ]
      end

      with_them do
        subject { described_class.new(pricing_rules: price_rules).calculate_score(cost:) }

        it { is_expected.to eq(expected_score) }
      end
    end
  end

end
