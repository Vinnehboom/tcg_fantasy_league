require 'rails_helper'

RSpec.describe ParticipationPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin) { create(:user, :with_role, role: :admin) }
  let(:participation) { create(:participation) }
  let(:user_participation) { create(:participation, user:) }

  permissions :show?, :destroy? do
    it { is_expected.not_to permit(user, participation) }
    it { is_expected.to permit(user, user_participation) }
    it { is_expected.to permit(admin, participation) }
  end

  permissions :create? do
    let(:admin_participation) { create(:participation, user: admin) }

    before do
      participation
      user_participation
      admin_participation
    end

    it { is_expected.to permit(user, build(:participation, user:)) }
    it { is_expected.to permit(admin, build(:participation, user: admin)) }
    it { is_expected.not_to permit(user, user_participation) }
    it { is_expected.not_to permit(admin, admin_participation) }
  end
end
