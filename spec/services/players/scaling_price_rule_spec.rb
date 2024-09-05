require 'rails_helper'

module Players

  RSpec.describe ScalingPriceRule do
    describe '#apply' do
      let(:player) { create(:player) }

      context 'when applying the default scales' do
        where(:current_cost, :score, :expected_cost) do
          [
            [0, 120, 17.00],
            [0, 250,  27.50],
            [13, 100, 23.00],
            [25, 100, 30.00]
          ]
        end

        with_them do
          before do
            create(:external_score, player:, score:)
          end

          it 'applies the price scales whose minimum cost is met' do
            cost = described_class.new.apply(cost: current_cost, score: player.current_score)
            expect(cost).to eq(expected_cost)
          end
        end
      end
    end
  end

end
