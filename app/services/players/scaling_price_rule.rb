module Players

  class ScalingPriceRule

    attr_accessor :scales

    def initialize(scales: default_scales)
      @scales = scales
    end

    def apply(cost:, score:)
      return cost unless score

      apply_scales(cost:, score:)
    end

    def apply_scales(cost:, score:)
      applicable_cost_scales(current_cost: cost).each do |scale|
        while cost < scale[:maximum_cost]
          break if score.negative? || score.zero?

          point_rest = score - scale[:point_coefficient]
          score -= scale[:point_coefficient]
          cost += if point_rest.positive? || point_rest.zero?
                    1.00
                  else
                    (scale[:point_coefficient] + point_rest) / scale[:point_coefficient]
                  end
        end
      end
      cost
    end

    def applicable_cost_scales(current_cost:)
      scales.filter { |scale| scale[:maximum_cost].blank? || scale[:maximum_cost] >= current_cost }
    end

    def default_scales # rubocop:disable Metrics/MethodLength
      [{
        minimum_cost: 0,
        maximum_cost: 10,
        point_coefficient: 5.00
      },
       {
         minimum_cost: 10,
         maximum_cost: 25,
         point_coefficient: 10.00
       },
       {
         minimum_cost: 25,
         maximum_cost: 40,
         point_coefficient: 20.00
       },
       {
         minimum_cost: 40,
         maximum_cost: 50,
         point_coefficient: 30.00
       },
       {
         minimum_cost: 50,
         maximum_cost: 999_999,
         point_coefficient: 50.00
       }]
    end

  end

end
