class PricePricingRule < ApplicationRecord

  belongs_to :price
  belongs_to :pricing_rule

end
