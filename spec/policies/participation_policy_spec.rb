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

    context 'when the draft tournament has not started yet' do
      let(:draft) { create(:salary_draft, tournament: create(:tournament, starting_date: 2.days.from_now)) }

      it { is_expected.to permit(user, build(:participation, user:, draft:)) }
      it { is_expected.to permit(admin, build(:participation, user: admin, draft:)) }
      it { is_expected.not_to permit(user, user_participation) }
      it { is_expected.not_to permit(admin, admin_participation) }
    end

    context 'when the draft tournament has started' do
      let(:draft) { create(:salary_draft, tournament: create(:tournament, starting_date: 2.days.ago)) }

      it { is_expected.not_to permit(user, build(:participation, user:, draft:)) }
      it { is_expected.not_to permit(admin, build(:participation, user: admin, draft:)) }
      it { is_expected.not_to permit(user, user_participation) }
      it { is_expected.not_to permit(admin, admin_participation) }
    end
  end

  permissions :update? do
    context 'when the participation is not submitted or completed' do
      let(:user_participation) { create(:participation, user:, status: 'created') }

      it { is_expected.to permit(user, user_participation) }
    end

    context 'when the participation is submitted' do
      let(:user_participation) { create(:participation, user:, status: %w[submitted completed].sample) }

      it { is_expected.not_to permit(user, user_participation) }
    end
  end
end
