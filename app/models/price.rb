class Price < ApplicationRecord

  belongs_to :player
  validates :value, presence: true
  validates :external_points, presence: true
  has_many :price_pricing_rules, dependent: :destroy
  has_many :pricing_rules, through: :price_pricing_rules

end
