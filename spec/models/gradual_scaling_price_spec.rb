require 'rails_helper'

RSpec.describe GradualScalingPrice do
  describe '#apply' do
    let(:player) { create(:player) }
    let(:price_rule) { create(:gradual_scaling_price) }

    before do
      create(:gradual_price_scale,
             gradual_scaling_price: price_rule,
             minimum_price: 0,
             maximum_price: 10,
             point_coefficient: 5)
      create(:gradual_price_scale,
             gradual_scaling_price: price_rule,
             minimum_price: 10,
             maximum_price: 25,
             point_coefficient: 10)
      create(:gradual_price_scale,
             gradual_scaling_price: price_rule,
             minimum_price: 25,
             maximum_price: 40,
             point_coefficient: 20)
      create(:gradual_price_scale,
             gradual_scaling_price: price_rule,
             minimum_price: 40,
             maximum_price: 50,
             point_coefficient: 30)
      create(:gradual_price_scale,
             gradual_scaling_price: price_rule,
             minimum_price: 50,
             maximum_price: 150,
             point_coefficient: 50)
    end

    where(:current_price, :external_points, :expected_price) do
      [
        [0, 120, 17],
        [0, 250,  27.5],
        [13, 100, 23],
        [25, 100, 30]
      ]
    end

    with_them do
      let(:price) { build(:price, value: current_price, external_points:, player:) }

      it 'applies the price scales whose minimum price is met' do
        price_rule.apply(price)
        expect(price.value).to eq(expected_price)
      end

      it 'adds the price rule to the price' do
        price_rule.apply(price)
        expect(price.pricing_rules).to include(price_rule)
      end
    end
  end
end
