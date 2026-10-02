require 'rails_helper'

RSpec.describe Tournament do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_presence_of(:starting_date) }
  it { is_expected.to have_many(:salary_drafts) }
  it { is_expected.to have_many(:results) }
  it { is_expected.to have_many(:external_requests).dependent(:nullify) }

  it { is_expected.to belong_to(:game) }

  describe '#results_imported?' do
    let(:tournament) { create(:tournament) }

    it 'is true when the tournament has a result' do
      create(:result, tournament:)

      expect(tournament).to be_results_imported
    end

    it 'is false when the tournament has no result' do
      expect(tournament).not_to be_results_imported
    end
  end

  describe '#season' do
    let(:game) { create(:game) }
    let(:tournament) { create(:tournament, game:, starting_date: Date.new(2026, 3, 1)) }

    it 'is the season covering the starting date' do
      season = create(:season, game:, start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 8, 31))

      expect(tournament.season).to eq(season)
    end

    it 'is nil when only an earlier season exists' do
      create(:season, game:, start_date: Date.new(2024, 9, 1), end_date: Date.new(2025, 8, 31))

      expect(tournament.season).to be_nil
    end

    it 'is nil when only a later season exists' do
      create(:season, game:, start_date: Date.new(2026, 9, 1), end_date: Date.new(2027, 8, 31))

      expect(tournament.season).to be_nil
    end

    it 'is an open-ended season that started before the starting date' do
      season = create(:season, game:, start_date: Date.new(2025, 9, 1), end_date: nil)

      expect(tournament.season).to eq(season)
    end
  end

  describe '#field_size' do
    describe 'when absent' do
      it 'is a valid tournament' do
        tournament = build(:tournament, field_size: nil)

        expect(tournament).to be_valid
      end
    end

    describe 'when a positive number' do
      it 'is a valid tournament' do
        tournament = build(:tournament, field_size: 128)

        expect(tournament).to be_valid
      end
    end

    describe 'when zero' do
      it 'is not a valid tournament' do
        tournament = build(:tournament, field_size: 0)

        expect(tournament).not_to be_valid
      end
    end

    describe 'when negative' do
      it 'is not a valid tournament' do
        tournament = build(:tournament, field_size: -1)

        expect(tournament).not_to be_valid
      end
    end
  end

  describe '#results_source_id' do
    describe 'when absent' do
      it 'is a valid tournament' do
        tournament = build(:tournament, results_source_id: nil)

        expect(tournament).to be_valid
      end
    end

    describe 'when set to a value not used by any other tournament' do
      it 'is a valid tournament' do
        tournament = build(:tournament, results_source_id: '0070')

        expect(tournament).to be_valid
      end
    end

    describe 'when another tournament already has the same value' do
      it 'is not a valid tournament' do
        create(:tournament, results_source_id: '0070')
        tournament = build(:tournament, results_source_id: '0070')

        expect(tournament).not_to be_valid
      end
    end
  end
end
