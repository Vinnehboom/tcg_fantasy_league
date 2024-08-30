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
end
