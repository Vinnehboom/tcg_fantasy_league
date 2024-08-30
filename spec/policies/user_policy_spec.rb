require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  permissions :show? do
    it { is_expected.to permit(user, user) }
    it { is_expected.not_to permit(user, other_user) }
  end
end
