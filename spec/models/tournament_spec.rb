require 'rails_helper'

RSpec.describe Tournament do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_presence_of(:starting_date) }
  it { is_expected.to have_many(:salary_drafts) }
  it { is_expected.to have_many(:results) }
  it { is_expected.to have_many(:external_requests).dependent(:nullify) }

  it { is_expected.to belong_to(:game) }

  describe '#destroy' do
    subject(:destroy) { tournament.destroy }

    let(:tournament) { create(:tournament) }
    let(:request) { create(:external_request, :discarded, requestable: tournament) }

    before { request }

    it 'nullifies a discarded external request pointing at the tournament' do
      destroy

      expect(request.reload.requestable_id).to be_nil
    end
  end
end
