require 'rails_helper'

RSpec.describe Participation do
  it { is_expected.to belong_to(:draft) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_one(:tournament) }
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to have_many(:rosters) }

  describe 'roster validation' do
    context 'when updating a participation' do
      subject { participation.update(status: 'submitted') }

      context 'when the participation has no rosters' do
        let(:participation) { create(:participation) }

        it { is_expected.to be_falsey }
      end

      context 'when the participation has rosters' do
        let(:participation) { create(:participation, :with_roster) }

        context 'when the rosters are empty' do
          before do
            participation.rosters.each { |roster| roster.roster_players.destroy_all }
          end

          it { is_expected.to be_falsey }
        end

        context 'when the rosters have players' do
          it { is_expected.to be_truthy }
        end
      end
    end
  end
end
