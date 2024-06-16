require 'rails_helper'

RSpec.describe Price do
  it { is_expected.to have_many(:price_pricing_rules) }
  it { is_expected.to have_many(:pricing_rules) }
end
