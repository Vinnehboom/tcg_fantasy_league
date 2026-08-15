require 'rails_helper'

RSpec.describe Admin::ExternalRequestsHelper do
  describe '#kind_label' do
    subject { helper.kind_label(external_request) }

    context 'when the kind is players' do
      let(:external_request) { build(:external_request, kind: :players) }

      it { is_expected.to eq('Players') }
    end

    context 'when the kind is tournaments' do
      let(:external_request) { build(:external_request, kind: :tournaments) }

      it { is_expected.to eq('Tournaments') }
    end
  end

  describe '#status_label' do
    subject { helper.status_label(external_request) }

    context 'when the status is running' do
      let(:external_request) { build(:external_request, status: :running) }

      it { is_expected.to eq('Running') }
    end

    context 'when the status is success' do
      let(:external_request) { build(:external_request, :success) }

      it { is_expected.to eq('Success') }
    end

    context 'when the status is failure' do
      let(:external_request) { build(:external_request, :failure) }

      it { is_expected.to eq('Failure') }
    end
  end
end
