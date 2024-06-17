class PricingRule < ApplicationRecord

  validates :name, presence: true
  has_many :price_pricing_rules, dependent: :destroy
  has_many :prices, through: :price_pricing_rules

  def apply(price); end

end
