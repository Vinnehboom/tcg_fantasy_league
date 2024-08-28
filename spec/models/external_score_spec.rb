require 'rails_helper'

RSpec.describe ExternalScore do
  it { is_expected.to belong_to(:player) }
end
