require 'rails_helper'

RSpec.describe SalaryDraft do
  it { is_expected.to validate_presence_of(:roster_size) }
  it { is_expected.to validate_presence_of(:price_cap) }
  it { is_expected.to belong_to(:tournament) }
end
