require 'rails_helper'

RSpec.describe PricePricingRule do
  it { is_expected.to belong_to(:price) }
  it { is_expected.to belong_to(:pricing_rule) }
end
