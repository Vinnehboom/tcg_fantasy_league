require 'rails_helper'

RSpec.describe GradualPriceScale do
  it { is_expected.to validate_presence_of(:point_coefficient) }
  it { is_expected.to validate_presence_of(:minimum_price) }
  it { is_expected.to validate_presence_of(:maximum_price) }
end
