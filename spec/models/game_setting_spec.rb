require 'rails_helper'

RSpec.describe GameSetting do
  it { is_expected.to belong_to(:season) }
  it { is_expected.to have_one(:game).through(:season) }
  it { is_expected.to validate_presence_of(:settings) }

  describe 'uniqueness' do
    subject(:new_game_setting) { build(:game_setting, season:) }

    let(:season) { create(:season) }

    before { create(:game_setting, season:) }

    it 'rejects a second row for the same season' do
      expect(new_game_setting).not_to be_valid
    end
  end
end
