require 'rails_helper'

RSpec.describe Demo::DraftSeeder do
  before do
    Demo::Seeder.call
    Demo::History.call
  end

  def past_draft
    SalaryDraft.joins(:tournament).where(tournaments: { starting_date: ...Date.current }).first
  end

  def upcoming_draft
    SalaryDraft.joins(:tournament).where(tournaments: { starting_date: Date.current.. }).first
  end

  describe '.call' do
    it 'creates the demo user' do
      described_class.call

      expect(User.find_by(username: 'demo')).to be_present
    end

    it 'creates an admin user' do
      described_class.call

      expect(User.find_by(username: 'admin')).to be_admin
    end

    it 'creates a SalaryDraft for every tournament' do
      described_class.call

      expect(SalaryDraft.count).to eq(Tournament.count)
    end

    it 'gives every roster player a positive cost on a past draft' do
      described_class.call

      expect(past_draft.participations.flat_map(&:roster_players).map(&:player_cost)).to all(be_positive)
    end

    it 'gives every roster player a positive cost on an upcoming draft' do
      described_class.call

      expect(upcoming_draft.participations.flat_map(&:roster_players).map(&:player_cost)).to all(be_positive)
    end

    it 'keeps every roster within its draft price_cap' do
      described_class.call

      Roster.find_each { |roster| expect(roster.total_cost).to be <= roster.draft.price_cap }
    end

    it 'produces a differentiated ranking, not a flat tie' do
      described_class.call
      totals = User.highscorers(game: Game.find('PTCG')).map(&:total)

      expect(totals.uniq.length).to be > 1
    end

    it 'completes exactly the configured number of participations on a past draft' do
      described_class.call

      expect(past_draft.participations.completed.count).to eq(described_class::PARTICIPANT_COUNT)
    end

    it 'is idempotent: a second call adds no rows' do
      described_class.call

      expect do
        described_class.call
      end.not_to(change { [User.count, SalaryDraft.count, Participation.count, Roster.count, RosterPlayer.count] })
    end
  end
end
