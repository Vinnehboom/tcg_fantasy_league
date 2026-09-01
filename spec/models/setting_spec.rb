require 'rails_helper'

RSpec.describe Setting do
  it { is_expected.to belong_to(:settingable) }
  it { is_expected.to belong_to(:season) }
  it { is_expected.to have_one(:game).through(:season) }
  it { is_expected.to validate_presence_of(:settings) }

  describe 'uniqueness' do
    subject(:new_setting) { build(:setting, season:) }

    let(:season) { create(:season) }

    before { create(:setting, season:) }

    it 'rejects a second row for the same season' do
      expect(new_setting).not_to be_valid
    end
  end

  describe '.for' do
    subject(:looked_up_setting) { described_class.for(season: lookup_season) }

    let(:game) { create(:game) }
    let(:early_season) do
      create(:season, game:, label: '2024', start_date: Date.new(2023, 9, 1), end_date: Date.new(2024, 8, 31))
    end
    let(:mid_season) do
      create(:season, game:, label: '2025', start_date: Date.new(2024, 9, 1), end_date: Date.new(2025, 8, 31))
    end
    let(:late_season) do
      create(:season, game:, label: '2026', start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 8, 31))
    end

    context 'when the looked-up season has its own row' do
      let(:lookup_season) { mid_season }
      let(:own_setting) { create(:setting, season: mid_season) }

      before do
        own_setting
        create(:setting, season: late_season)
      end

      it 'returns that season\'s own row' do
        expect(looked_up_setting).to eq(own_setting)
      end
    end

    context 'when the looked-up season has no row of its own but an earlier season does' do
      let(:lookup_season) { late_season }
      let(:nearest_prior_setting) { create(:setting, season: mid_season) }

      before do
        create(:setting, season: early_season)
        nearest_prior_setting
      end

      it 'carries forward the nearest prior season\'s row' do
        expect(looked_up_setting).to eq(nearest_prior_setting)
      end
    end

    context 'when only a later season has a row' do
      let(:lookup_season) { early_season }

      before { create(:setting, season: late_season) }

      it 'does not fall forward, returning nil' do
        expect(looked_up_setting).to be_nil
      end
    end

    context 'when the game has no Setting row at all' do
      let(:lookup_season) { mid_season }

      it { is_expected.to be_nil }
    end

    context 'when the looked-up season is itself open and has no row of its own' do
      let(:open_season) { create(:season, game:, label: 'open', start_date: Date.new(2026, 9, 1), end_date: nil) }
      let(:lookup_season) { open_season }
      let(:nearest_prior_setting) { create(:setting, season: late_season) }

      before do
        create(:setting, season: early_season)
        nearest_prior_setting
      end

      it 'carries forward the nearest prior closed season\'s row' do
        expect(looked_up_setting).to eq(nearest_prior_setting)
      end
    end

    context 'when only a different game has a configured row' do
      let(:lookup_season) { late_season }
      let(:other_game) { create(:game) }
      let(:other_season) do
        create(:season, game: other_game, label: '2024',
                        start_date: Date.new(2023, 9, 1), end_date: Date.new(2024, 8, 31))
      end

      before { create(:setting, season: other_season) }

      it 'never falls back to another game\'s row' do
        expect(looked_up_setting).to be_nil
      end
    end
  end
end
