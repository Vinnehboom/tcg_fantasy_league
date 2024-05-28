require 'rails_helper'

RSpec.describe Player do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:country) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_presence_of(:external_points) }
end
