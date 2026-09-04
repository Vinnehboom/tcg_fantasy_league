require 'rails_helper'

RSpec.describe Demo::History do
  before { Demo::Seeder.call }

  describe '.call' do
    it 'creates five score rows per player, each with a distinct created_at' do
      described_class.call

      Demo::Games::ALL.each do |entry|
        game = Game.find(entry.id)
        game.players.find_each do |player|
          created_ats = player.external_scores.pluck(:created_at)

          expect(created_ats.uniq.length).to eq(5)
        end
      end
    end

    it 'names only players the players import already created' do
      expect { described_class.call }.not_to change(Player, :count)
    end

    it 'creates past tournaments dated before today' do
      described_class.call

      expect(Tournament.where('external_id LIKE ?', '/tournaments/past-%').pluck(:starting_date))
        .to all(be < Date.current)
    end

    it "computes latest_score_before as greater than zero at each past tournament's date" do
      described_class.call

      Demo::Games::ALL.each do |entry|
        game = Game.find(entry.id)
        past_tournaments = game.tournaments.where('external_id LIKE ?', '/tournaments/past-%')

        past_tournaments.each do |tournament|
          game.players.find_each do |player|
            expect(player.latest_score_before(date: tournament.starting_date)).to be_positive
          end
        end
      end
    end

    it 'is idempotent: a second call adds no rows' do
      described_class.call

      expect do
        described_class.call
      end.not_to(change { [ExternalScore.count, Tournament.count, Result.count] })
    end
  end
end
