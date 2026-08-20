require 'rails_helper'

RSpec.describe Season do
  it { is_expected.to belong_to(:game) }
  it { is_expected.to validate_presence_of(:label) }
  it { is_expected.to validate_presence_of(:start_date) }
  it { is_expected.to validate_presence_of(:end_date) }

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
  end
end
