module Demo

  # The demo's main entry point (H-9): a Game and an open-ended Season per
  # Demo::Games entry, then the real players and upcoming-tournaments import
  # against the synthetic adapter. Additive and idempotent — every lookup
  # guards its own create, and the import jobs are themselves idempotent, so
  # a second call adds no rows (it does refresh upcoming tournament dates,
  # which is wanted: see Decisions D11).
  #
  # No results and no past tournaments here — see Demo::History for the
  # historical slice, and Demo::DraftSeeder for the app-domain half.
  class Seeder

    # Shared across every demo composition root that needs one (this class,
    # Demo::History, Demo::DraftSeeder), so the players and results imports
    # for one game always draw from the same pool — see Decisions D8.
    SEED = 947_628

    def self.call
      new.call
    end

    def call
      Demo::Games::ALL.each { |entry| seed_game(entry) }
    end

    private

    def seed_game(entry)
      game = ensure_game(entry)
      ensure_season(game, entry)
      import_players(game, entry)
      import_tournaments(game, entry)
    end

    def ensure_game(entry)
      ::Game.find_by(id: entry.id) ||
        ::Game.create!(id: entry.id, name: entry.name, base_uri: entry.base_uri)
    end

    def ensure_season(game, entry)
      ::Season.find_by(game:, label: entry.season_label) ||
        ::Season.create!(game:, label: entry.season_label, start_date: 1.year.ago.to_date, end_date: nil)
    end

    def import_players(game, entry)
      ExternalData::Synthetic::ImportPlayersJob.perform_now(game_id: game.id, seed: SEED, shape: entry.shape)
    end

    def import_tournaments(game, entry)
      ExternalData::Synthetic::ImportTournamentsJob.perform_now(game_id: game.id, seed: SEED, shape: entry.shape)
    end

  end

end
