require 'rails_helper'

RSpec.describe Season do
  it { is_expected.to belong_to(:game) }
  it { is_expected.to validate_presence_of(:label) }
  it { is_expected.to validate_presence_of(:start_date) }

  describe 'date range validation' do
    subject(:season) { build(:season, game:, start_date:, end_date:) }

    let(:game) { create(:game) }
    let(:start_date) { Date.new(2025, 9, 1) }
    let(:end_date) { Date.new(2026, 8, 31) }

    context 'when the end date is on or after the start date' do
      it { is_expected.to be_valid }
    end

    context 'when the end date is before the start date' do
      let(:end_date) { start_date - 1.day }

      it { is_expected.not_to be_valid }
    end

    context 'when there is no end date' do
      let(:end_date) { nil }

      it 'is valid, since a null end date represents an open season' do
        expect(season).to be_valid
      end
    end
  end

  describe '.covering' do
    subject(:covering) { described_class.covering(date) }

    let(:game) { create(:game) }

    context 'when the date falls inside a closed season' do
      let(:closed_season) do
        create(:season, game:, start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 8, 31))
      end
      let(:date) { Date.new(2026, 1, 15) }

      before { closed_season }

      it { is_expected.to contain_exactly(closed_season) }
    end

    context 'when the date is after every closed season and none is open' do
      let(:closed_season) do
        create(:season, game:, start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 8, 31))
      end
      let(:date) { Date.new(2030, 1, 1) }

      before { closed_season }

      it { is_expected.to be_empty }
    end

    context 'when the date is far in the future but covered by an open season' do
      let(:open_season) { create(:season, game:, start_date: Date.new(2025, 9, 1), end_date: nil) }
      let(:date) { Date.new(2099, 1, 1) }

      before { open_season }

      it { is_expected.to contain_exactly(open_season) }
    end

    context "when the date is before an open season's own start date" do
      let(:open_season) { create(:season, game:, start_date: Date.new(2025, 9, 1), end_date: nil) }
      let(:date) { Date.new(2025, 8, 31) }

      before { open_season }

      it { is_expected.to be_empty }
    end
  end

  describe 'overlap validation' do
    subject(:new_season) { build(:season, game:, start_date:, end_date:) }

    let(:game) { create(:game) }

    before { create(:season, game:, start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 8, 31)) }

    context 'when the new range overlaps an existing season for the same game' do
      let(:start_date) { Date.new(2026, 6, 1) }
      let(:end_date) { Date.new(2027, 5, 31) }

      it { is_expected.not_to be_valid }
    end

    context 'when the new range does not overlap any existing season for the same game' do
      let(:start_date) { Date.new(2026, 9, 1) }
      let(:end_date) { Date.new(2027, 8, 31) }

      it { is_expected.to be_valid }
    end

    context 'when the overlapping range belongs to a different game' do
      subject(:new_season) { build(:season, game: other_game, start_date:, end_date:) }

      let(:other_game) { create(:game) }
      let(:start_date) { Date.new(2025, 9, 1) }
      let(:end_date) { Date.new(2026, 8, 31) }

      it { is_expected.to be_valid }
    end

    context 'when a new open season overlaps an earlier closed season' do
      let(:start_date) { Date.new(2026, 6, 1) }
      let(:end_date) { nil }

      it { is_expected.not_to be_valid }
    end

    context 'when a new closed season overlaps an existing open season' do
      before { create(:season, game:, start_date: Date.new(2027, 1, 1), end_date: nil) }

      let(:start_date) { Date.new(2026, 12, 1) }
      let(:end_date) { Date.new(2027, 6, 30) }

      it { is_expected.not_to be_valid }
    end

    context 'when a new open season starts after every existing season ends' do
      let(:start_date) { Date.new(2026, 9, 1) }
      let(:end_date) { nil }

      it { is_expected.to be_valid }
    end
  end
end
