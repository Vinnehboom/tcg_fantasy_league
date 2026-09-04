require 'rails_helper'

RSpec.describe Demo::Seeder do
  describe '.call' do
    context 'when Rails.env is production' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production')) }

      it 'raises instead of seeding anything' do
        expect { described_class.call }.to raise_error(RuntimeError, /must never run/)
      end
    end

    it 'creates a Game row for every demo game' do
      expect { described_class.call }.to change(Game, :count).by(Demo::Games::ALL.length)
    end

    it 'creates an open-ended Season for every demo game' do
      described_class.call

      expect(Season.where(end_date: nil).count).to eq(Demo::Games::ALL.length)
    end

    it 'imports the configured number of players for each game' do
      described_class.call

      Demo::Games::ALL.each { |entry| expect(Player.where(game_id: entry.id).count).to eq(entry.shape.player_count) }
    end

    it 'imports the configured number of upcoming tournaments for each game' do
      described_class.call

      Demo::Games::ALL.each do |entry|
        expect(Tournament.where(game_id: entry.id).count).to eq(entry.shape.tournament_count)
      end
    end

    it 'imports no tournament dated less than 7 days out, for any game' do
      described_class.call

      expect(Tournament.pluck(:starting_date)).to all(be >= 7.days.from_now.to_date)
    end

    it 'is idempotent: a second call adds no Game, Season, Player or ExternalScore rows' do
      described_class.call

      expect do
        described_class.call
      end.not_to(change { [Game.count, Season.count, Player.count, ExternalScore.count] })
    end

    it 'refreshes upcoming tournament dates on a second call, since they are offsets from today' do
      described_class.call
      first_dates = Tournament.order(:external_id).pluck(:starting_date)

      travel_to(2.days.from_now) { described_class.call }

      expect(Tournament.order(:external_id).pluck(:starting_date)).not_to eq(first_dates)
    end
  end
end
