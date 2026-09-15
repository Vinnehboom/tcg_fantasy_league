require 'rails_helper'

RSpec.describe DataSubjectRequest do
  it { is_expected.to belong_to(:player) }
  it { is_expected.to validate_presence_of(:request_type) }
  it { is_expected.to validate_presence_of(:status) }

  describe 'validating contact information' do
    it 'is valid with a contact email and no identity proof' do
      data_subject_request = build(:data_subject_request, contact_email: 'player@example.com', identity_proof: nil)

      expect(data_subject_request).to be_valid
    end

    it 'is valid with identity proof and no contact email' do
      data_subject_request = build(:data_subject_request, contact_email: nil, identity_proof: 'My passport number')

      expect(data_subject_request).to be_valid
    end

    it 'is invalid with neither a contact email nor identity proof' do
      data_subject_request = build(:data_subject_request, contact_email: nil, identity_proof: nil)

      expect(data_subject_request).not_to be_valid
    end
  end

  describe '#mark_actioned!' do
    context 'when the player is not already suppressed' do
      let(:player) { create(:player) }
      let(:data_subject_request) { create(:data_subject_request, player:) }

      before do
        freeze_time
        data_subject_request.mark_actioned!
      end

      it 'marks the request actioned' do
        expect(data_subject_request.status).to eq('actioned')
      end

      it 'stamps the time it was actioned' do
        expect(data_subject_request.actioned_at).to eq(Time.current)
      end

      it 'suppresses the player' do
        expect(player.reload.suppressed_at).to eq(Time.current)
      end
    end

    context 'when the player is already suppressed' do
      let(:original_suppressed_at) { 1.day.ago }
      let(:player) { create(:player, suppressed_at: original_suppressed_at) }
      let(:data_subject_request) { create(:data_subject_request, player:) }

      before { data_subject_request.mark_actioned! }

      it "does not move the player's existing suppression time" do
        expect(player.reload.suppressed_at).to be_within(1.second).of(original_suppressed_at)
      end
    end
  end
end
