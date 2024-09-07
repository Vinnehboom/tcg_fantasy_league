require 'rails_helper'

RSpec.describe Participation do
  it { is_expected.to belong_to(:draft) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_one(:tournament) }
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to have_many(:rosters) }
end
