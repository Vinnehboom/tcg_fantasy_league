require 'rails_helper'

RSpec.describe Game do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:base_uri) }

  it { is_expected.to have_many(:players) }
  it { is_expected.to have_many(:tournaments) }
  it { is_expected.to have_many(:external_requests).dependent(:restrict_with_error) }
  it { is_expected.to have_one(:default_setting).dependent(:destroy) }

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

  describe '#current_season' do
    subject(:current) { game.current_season(on: date) }

    let(:game) { create(:game) }
    let(:season_start) { Date.new(2025, 9, 1) }
    let(:season_end) { Date.new(2026, 8, 31) }

    before { create(:season, game:, start_date: season_start, end_date: season_end) }

    context 'when a season covers the given date' do
      let(:date) { Date.new(2026, 1, 15) }

      it { is_expected.to have_attributes(label: '2026') }
    end

    context 'when no season covers the given date' do
      let(:date) { Date.new(2030, 1, 1) }

      it { is_expected.to be_nil }
    end

    context 'when an open season covers the given date' do
      before { create(:season, game:, label: 'open', start_date: Date.new(2026, 9, 1), end_date: nil) }

      let(:date) { Date.new(2099, 1, 1) }

      it { is_expected.to have_attributes(label: 'open') }
    end

    context 'when no date is given' do
      subject(:current) { game.current_season }

      # Anchored to today, not a fixed range, so this does not expire like a
      # hardcoded date range eventually would (it did, on 2026-09-01).
      let(:season_start) { 1.year.ago.to_date }
      let(:season_end) { 1.year.from_now.to_date }
      let(:date) { Date.current }

      it { is_expected.to have_attributes(label: '2026') }
    end

    context 'when called more than once for the same date' do
      let(:date) { Date.new(2026, 1, 15) }

      it 'memoizes the result instead of querying again' do
        first = current
        second = game.current_season(on: date)

        expect(second).to equal(first)
      end
    end
  end
end
