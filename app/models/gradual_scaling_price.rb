class GradualScalingPrice < PricingRule

  has_many :gradual_price_scales, dependent: :destroy

  def apply(price)
    value = price.value
    points_total = price.external_points.to_i
    applicable_price_scales(value).each do |grade|
      while value < grade.maximum_price
        break if points_total.negative? || points_total.zero?

        point_rest = points_total - grade.point_coefficient
        points_total -= grade.point_coefficient
        value += if point_rest.positive? || point_rest.zero?
                   1.00
                 else
                   (grade.point_coefficient + point_rest) / grade.point_coefficient
                 end
      end
    end
    price.value = value
    price.pricing_rules << self
  end

  def applicable_price_scales(current_price)
    gradual_price_scales.filter { |gr| gr.maximum_price.blank? || gr.maximum_price >= current_price }
  end

end
