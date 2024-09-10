require 'rails_helper'

module Players

  RSpec.describe CostCalculator do
    describe '#calculate_cost' do
      let(:tournament) { create(:tournament) }
      let(:player) do
        player = create(:player, :without_scores)
        create(:external_score, score: 50, player:)
        player
      end

      where(:price_rules, :expected_cost) do
        [
          [[], 0.0],
          [[ScalingPriceRule.new], 10.0],
          [[ScalingPriceRule.new], 10.0],
          [[ScalingPriceRule.new(scales: [
                                   {
                                     minimum_cost: 0,
                                     maximum_cost: 20,
                                     point_coefficient: 2.00
                                   }
                                 ])], 20.0]
        ]
      end

      with_them do
        subject { described_class.new(pricing_rules: price_rules).calculate_cost(player:, tournament:) }

        it { is_expected.to eq(expected_cost) }
      end
    end
  end

end
