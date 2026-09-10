require 'rails_helper'

RSpec.describe User do
  it { is_expected.to validate_presence_of(:username) }
  it { is_expected.to validate_uniqueness_of(:username) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_presence_of(:country) }
  it { is_expected.to validate_presence_of(:date_of_birth) }
  it { is_expected.to have_many(:participations) }
  it { is_expected.to have_many(:rosters) }

  describe 'country validation' do
    subject(:user) { build(:user, country:) }

    context 'with a code that is not a real ISO 3166-1 alpha-2 country' do
      let(:country) { 'ZZ' }

      it 'is invalid' do
        expect(user).not_to be_valid
      end
    end

    context 'with a real ISO 3166-1 alpha-2 country code' do
      let(:country) { 'FR' }

      it 'is valid' do
        expect(user).to be_valid
      end
    end
  end

  describe 'date_of_birth validation' do
    subject(:user) { build(:user, date_of_birth:) }

    context 'with a date in the future' do
      let(:date_of_birth) { 1.day.from_now.to_date }

      it 'is invalid' do
        expect(user).not_to be_valid
      end
    end

    context 'with a date in the past' do
      let(:date_of_birth) { 1.day.ago.to_date }

      it 'is valid' do
        expect(user).to be_valid
      end
    end
  end

  describe '#age' do
    subject { user.age }

    context 'with no date of birth' do
      let(:user) { build(:user, date_of_birth: nil) }

      it { is_expected.to be_nil }
    end

    context 'when it is the day before the birthday' do
      let(:user) { build(:user, date_of_birth: Date.current - 18.years + 1.day) }

      it { is_expected.to eq(17) }
    end

    context 'when it is the birthday' do
      let(:user) { build(:user, date_of_birth: Date.current - 18.years) }

      it { is_expected.to eq(18) }
    end

    context 'when it is the day after the birthday' do
      let(:user) { build(:user, date_of_birth: Date.current - 18.years - 1.day) }

      it { is_expected.to eq(18) }
    end
  end

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

  describe 'devise mail delivery' do
    it 'does not block user creation on the mail actually being delivered' do
      expect { create(:user, :unconfirmed) }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      expect { perform_enqueued_jobs }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end
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
