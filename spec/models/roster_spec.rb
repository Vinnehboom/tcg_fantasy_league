require 'rails_helper'

RSpec.describe Roster do
  it { is_expected.to belong_to(:participation) }
  it { is_expected.to have_many(:roster_players) }
  it { is_expected.to have_many(:players) }
end
