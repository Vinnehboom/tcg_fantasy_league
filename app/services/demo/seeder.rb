module Demo

  # No results and no past tournaments here — see Demo::History.
  class Seeder < ApplicationService

    include ProductionGuard

    # Shared with Demo::History, so the players and results imports for one
    # game always draw from the same pool.
    SEED = ExternalData::Synthetic::Adapter::DEFAULT_SEED

    def call
      raise_outside_the_sandbox!
      Demo::Games::ALL.each { |entry| seed_game(entry) }
    end

    private

    def seed_game(entry)
      game = ensure_game(entry)
      ensure_season(game:, entry:)
      adapter = synthetic_adapter(game:, entry:)
      import_players(game:, adapter:)
      import_tournaments(game:, adapter:)
    end

    def ensure_game(entry)
      ::Game.find_by(id: entry.id) ||
        ::Game.create!(id: entry.id, name: entry.name, base_uri: entry.base_uri)
    end

    def ensure_season(game:, entry:)
      ::Season.find_by(game:, label: entry.season_label) ||
        ::Season.create!(game:, label: entry.season_label, start_date: 1.year.ago.to_date, end_date: nil)
    end

    def synthetic_adapter(game:, entry:)
      ExternalData::Synthetic::Adapter.new(game:, seed: SEED, shape: entry.shape)
    end

    def import_players(game:, adapter:)
      ExternalData::ImportPlayersJob.perform_now(game_id: game.id, adapter:)
    end

    def import_tournaments(game:, adapter:)
      ExternalData::ImportTournamentsJob.perform_now(game_id: game.id, adapter:)
    end

  end

end
