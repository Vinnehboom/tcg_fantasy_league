require 'rails_helper'

RSpec.describe ExternalRequest do
  it { is_expected.to belong_to(:game) }
  it { is_expected.to belong_to(:requestable).optional }
  it { is_expected.to validate_presence_of(:kind) }
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to validate_presence_of(:started_at) }
  it { is_expected.to validate_numericality_of(:records_processed).only_integer.is_greater_than_or_equal_to(0) }

  describe '#duration_seconds' do
    subject { external_request.duration_seconds }

    context 'when the request has finished' do
      let(:external_request) { build(:external_request, started_at: 10.seconds.ago, finished_at: Time.current) }

      it { is_expected.to be_within(0.1).of(10) }
    end

    context 'when the request is still running' do
      let(:external_request) { build(:external_request, started_at: 10.seconds.ago, finished_at: nil) }

      it { is_expected.to be_nil }
    end
  end

  describe '#mark_success' do
    let(:external_request) { create(:external_request) }

    context 'when finished_at is not given' do
      before do
        freeze_time
        external_request.mark_success(records_processed: 5)
      end

      it 'marks the request as a success' do
        expect(external_request.status).to eq('success')
      end

      it 'stores the number of records processed' do
        expect(external_request.records_processed).to eq(5)
      end

      it 'stamps the time the request finished as now' do
        expect(external_request.finished_at).to eq(Time.current)
      end
    end

    context 'when finished_at is given' do
      let(:custom_finished_at) { Time.zone.local(2026, 1, 1, 9, 0, 0) }

      before do
        external_request.mark_success(records_processed: 5, finished_at: custom_finished_at)
      end

      it 'honors the given finished_at instead of now' do
        expect(external_request.finished_at).to eq(custom_finished_at)
      end
    end
  end

  describe '#mark_failure' do
    let(:external_request) { create(:external_request) }

    context 'when finished_at is not given' do
      before do
        freeze_time
        external_request.mark_failure(error: 'boom')
      end

      it 'marks the request as a failure' do
        expect(external_request.status).to eq('failure')
      end

      it 'stores the error' do
        expect(external_request.error).to eq('boom')
      end

      it 'stamps the time the request finished as now' do
        expect(external_request.finished_at).to eq(Time.current)
      end
    end

    context 'when finished_at is given' do
      let(:custom_finished_at) { Time.zone.local(2026, 1, 1, 9, 0, 0) }

      before do
        external_request.mark_failure(error: 'boom', finished_at: custom_finished_at)
      end

      it 'honors the given finished_at instead of now' do
        expect(external_request.finished_at).to eq(custom_finished_at)
      end
    end
  end
end
