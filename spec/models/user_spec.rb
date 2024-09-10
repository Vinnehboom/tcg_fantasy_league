require 'rails_helper'

RSpec.describe User do
  it { is_expected.to validate_presence_of(:username) }
  it { is_expected.to validate_uniqueness_of(:username) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to have_many(:participations) }
  it { is_expected.to have_many(:rosters) }

  describe '#highscore' do
    subject { user.highscore }

    let(:user) { create(:user) }

    before do
      create(:roster_player,
             roster: create(:roster,
                            participation: create(:participation, user:)),
             score: 20)

      create(:roster_player,
             roster: create(:roster,
                            participation: create(:participation, user:)),
             score: 30)
    end

    it { is_expected.to eq(50.0) }
  end
end
