require 'rails_helper'

RSpec.describe RosterPlayer do
  it { is_expected.to belong_to(:roster) }
  it { is_expected.to belong_to(:player) }
end
