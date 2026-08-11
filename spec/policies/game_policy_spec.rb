require 'rails_helper'

RSpec.describe GamePolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin) { create(:user, :with_role, role: :admin) }
  let(:game) { create(:game) }

  permissions :trigger_import? do
    it { is_expected.not_to permit(user, game) }
    it { is_expected.to permit(admin, game) }
  end
end
