require 'rails_helper'

RSpec.describe Participation do
  it { is_expected.to belong_to(:draft) }
  it { is_expected.to belong_to(:user) }
end
