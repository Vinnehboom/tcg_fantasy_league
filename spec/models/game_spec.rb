require 'rails_helper'

RSpec.describe Game do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:base_uri) }

  it { is_expected.to have_many(:players) }
end
