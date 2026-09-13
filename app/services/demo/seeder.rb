module Demo

  # No results and no past tournaments here — see Demo::History.
  class Seeder < ApplicationService

    include ProductionGuard

    # Shared with Demo::History, so the players and results imports for one
    # game always draw from the same pool.
    SEED = ExternalData::Synthetic::Adapter::DEFAULT_SEED

    # ScoreModifier carries no game_id: this list is shared across every game.
    MODIFIER_ATTACHMENTS = [
      { score_modifier_class: ::Multiplier, factory: :multiplier, name: 'hot streak' },
      { score_modifier_class: ::Bonus, factory: :bonus, name: 'winner' }
    ].freeze

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
      attach_score_modifiers(game:)
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

    def attach_score_modifiers(game:)
      player_season = modifier_player_season(game:)
      MODIFIER_ATTACHMENTS.each { |attachment| ensure_modifier_attached(player_season:, **attachment) }
    end

    # Orders by player_id, not external_id, so this always picks the same
    # player that UiCapture::CoreTargets#seeded_record resolves for the
    # admin player page (Rails' implicit .first is ORDER BY id ASC).
    def modifier_player_season(game:)
      season = game.current_season || raise("#{game.id} has no current season")
      season.player_seasons.order(:player_id).first ||
        raise("#{game.id}'s season has no seeded player")
    end

    def ensure_modifier_attached(player_season:, score_modifier_class:, factory:, name:)
      score_modifier = score_modifier_class.find_by(name:) || FactoryBot.create(factory, name:)
      ::PlayerSeasonModifier.find_by(player_season:, score_modifier:) ||
        FactoryBot.create(:player_season_modifier, player_season:, score_modifier:)
    end

  end

end
