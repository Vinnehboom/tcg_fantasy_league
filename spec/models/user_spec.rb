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

  describe '.highscorers' do
    let(:game) { create(:game) }
    let(:users) { create_list(:user, 3) }

    it 'includes all users with scored rosters' do
      user1, user2 = users
      create(:roster_player,
             player: create(:player, game:),
             roster: create(:roster,
                            participation: create(:participation, user: user1)), score: 20)
      create(:roster_player,
             player: create(:player, game:),
             roster: create(:roster,
                            participation: create(:participation, user: user2)), score: nil)
      highscorers = described_class.highscorers(game:)
      expect(highscorers).to include(user1)
      expect(highscorers).not_to include(user2)
    end

    it 'sorts the user by highest total score' do
      user1, user2, user3 = users
      create(:roster_player,
             player: create(:player, game:),
             roster: create(:roster,
                            participation: create(:participation, user: user1)), score: 20)
      create(:roster_player,
             player: create(:player, game:),
             roster: create(:roster,
                            participation: create(:participation, user: user2)), score: 30)
      create(:roster_player,
             player: create(:player, game:),
             roster: create(:roster,
                            participation: create(:participation, user: user3)), score: 10)
      highscorers = described_class.highscorers(game:)
      expect(highscorers).to eq([user2, user1, user3])
    end
  end
end
