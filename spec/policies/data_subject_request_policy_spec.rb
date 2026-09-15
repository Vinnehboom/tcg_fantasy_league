require 'rails_helper'

RSpec.describe DataSubjectRequestPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin) { create(:user, :with_role, role: :admin) }

  permissions :mark_actioned? do
    context 'when the request is still queued' do
      let(:data_subject_request) { create(:data_subject_request) }

      it { is_expected.not_to permit(user, data_subject_request) }
      it { is_expected.to permit(admin, data_subject_request) }
    end

    context 'when the request has already been actioned' do
      let(:data_subject_request) { create(:data_subject_request, :actioned) }

      it { is_expected.not_to permit(user, data_subject_request) }
      it { is_expected.not_to permit(admin, data_subject_request) }
    end
  end
end
