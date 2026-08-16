require 'rails_helper'

RSpec.describe Game do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:base_uri) }

  it { is_expected.to have_many(:players) }
  it { is_expected.to have_many(:tournaments) }
  it { is_expected.to have_many(:external_requests).dependent(:restrict_with_error) }

  describe '#destroy' do
    subject(:destroy) { game.destroy }

    let(:game) { create(:game) }
    let(:request) { create(:external_request, game:) }

    before { request }

    it 'refuses to destroy a game with external requests' do
      destroy

      expect(game).to be_persisted
    end

    it 'leaves the external request audit trail intact' do
      destroy

      expect(ExternalRequest.exists?(request.id)).to be(true)
    end

    context 'when its only external request is discarded' do
      let(:request) { create(:external_request, :discarded, game:) }

      it 'still refuses to destroy the game' do
        destroy

        expect(game).to be_persisted
      end
    end
  end

  describe '.upcoming_drafts' do
    subject { game.upcoming_drafts }

    let(:game) { create(:game) }

    let!(:passed_draft) { create(:salary_draft, tournament: create(:tournament, game:, starting_date: 1.day.ago)) }
    let!(:upcoming_draft) do
      create(:salary_draft, tournament: create(:tournament, game:, starting_date: 1.day.from_now))
    end

    it { is_expected.to include(upcoming_draft) }
    it { is_expected.not_to include(passed_draft) }
  end
end
