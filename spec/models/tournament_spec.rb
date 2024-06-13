require 'rails_helper'

RSpec.describe Tournament do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_presence_of(:starting_date) }

  it { is_expected.to belong_to(:game) }
end
