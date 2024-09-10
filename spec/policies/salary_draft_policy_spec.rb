require 'rails_helper'

RSpec.describe SalaryDraftPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin) { create(:user, :with_role, role: :admin) }
  let(:salary_draft) { create(:salary_draft) }

  permissions :new?, :edit?, :create?, :update?, :destroy? do
    it { is_expected.not_to permit(user, salary_draft) }
    it { is_expected.to permit(admin, salary_draft) }
  end

  permissions :complete? do
    context "when the draft's tournament has commenced" do
      before do
        salary_draft.tournament.update(starting_date: 2.days.ago)
      end

      it { is_expected.not_to permit(user, salary_draft) }
      it { is_expected.to permit(admin, salary_draft) }
    end

    context "when the draft's tournament has not commenced" do
      before do
        salary_draft.tournament.update(starting_date: 2.days.from_now)
      end

      it { is_expected.not_to permit(user, salary_draft) }
      it { is_expected.not_to permit(admin, salary_draft) }
    end
  end
end
