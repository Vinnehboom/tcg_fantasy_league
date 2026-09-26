require 'rails_helper'

RSpec.describe SeasonPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin) { create(:user, :with_role, role: :admin) }
  let(:season) { create(:season) }

  permissions :new?, :create?, :edit?, :update? do
    it { is_expected.not_to permit(user, season) }
    it { is_expected.to permit(admin, season) }
  end
end
