require 'rails_helper'

RSpec.describe PricingRule do
  it { is_expected.to have_many(:price_pricing_rules) }
  it { is_expected.to have_many(:prices) }
  it { is_expected.to validate_presence_of(:name) }
end
