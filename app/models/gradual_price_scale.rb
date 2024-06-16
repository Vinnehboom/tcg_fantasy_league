class GradualPriceScale < ApplicationRecord

  belongs_to :gradual_scaling_price
  validates :minimum_price, presence: true
  validates :maximum_price, presence: true
  validates :point_coefficient, presence: true

end
