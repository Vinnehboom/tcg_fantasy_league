require 'rails_helper'

RSpec.describe RosterPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:participation) { create(:participation, user:) }
  let(:admin) { create(:user, :with_role, role: :admin) }
  let(:roster) { create(:roster) }
  let(:user_roster) { create(:roster, participation: create(:participation, user:)) }

  permissions :show?, :edit?, :update?, :destroy? do
    it { is_expected.not_to permit(user, roster) }
    it { is_expected.to permit(user, user_roster) }
    it { is_expected.to permit(admin, roster) }
  end

  permissions :create? do
    context 'when the user has no rosters for the participation' do
      it { is_expected.to permit(user, build(:roster, participation: create(:participation, user:))) }
    end

    context 'when the user has a roster for the participation' do
      before do
        create(:roster, participation:)
      end

      it { is_expected.not_to permit(user, build(:roster, participation:)) }
    end
  end
end
