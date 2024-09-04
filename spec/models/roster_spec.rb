require 'rails_helper'

RSpec.describe Roster do
  it { is_expected.to belong_to(:participation) }
  it { is_expected.to have_one(:draft) }
  it { is_expected.to have_one(:tournament) }
  it { is_expected.to have_many(:roster_players) }
  it { is_expected.to have_many(:players) }

  describe '#roster_size validation' do
    subject { roster }

    let(:roster_size) { 2 }
    let(:roster) { create(:roster, participation: create(:participation, draft: create(:salary_draft, roster_size:))) }

    context 'when the roster is not full' do
      before do
        roster.roster_players.new(player: create(:player))
      end

      it { is_expected.to be_valid }
    end

    context 'when the roster is full' do
      before do
        create_list(:roster_player, roster_size, roster:)
        roster.reload
        roster.roster_players.new(player: create(:player))
      end

      it { is_expected.not_to be_valid }
    end
  end
end
