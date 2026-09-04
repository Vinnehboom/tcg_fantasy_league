module Demo

  # The demo's historical slice (H-9): backdated score checkpoints and a
  # handful of past, completed tournaments, so a finished draft and the
  # leaderboard have something real to show. Create-once, keyed on the past
  # tournaments' fixed external ids — see Demo::Seeder's own docs for why
  # this half is not additive like it is.
  #
  # Only the historical ExternalScore rows' time axis is hand-written: there
  # is no external source for "what this player's rating was three months
  # ago". Everything else — the tournaments' Result rows, and every score's
  # own validations — still goes through the app's own code, same as
  # Demo::Seeder.
  class History < ApplicationService

    include ProductionGuard

    CHECKPOINT_DAYS_AGO = [120, 75, 45, 15].freeze
    PAST_TOURNAMENT_INTERVAL_DAYS = 30
    PAST_TOURNAMENT_COUNTRIES = %w[US GB JP DE FR].freeze
    HISTORY_HORIZON_DAYS = 150.0

    def call
      raise_outside_the_sandbox!
      Demo::Games::ALL.each { |entry| seed_history(entry) }
    end

    private

    def seed_history(entry)
      game = ::Game.find(entry.id)
      return if already_seeded?(game)

      backdate_scores(game:, entry:)
      tournaments = create_past_tournaments(game:, entry:)
      import_results(tournaments:, entry:)
    end

    def already_seeded?(game)
      ::Tournament.exists?(game_id: game.id, external_id: past_external_id(1))
    end

    def backdate_scores(game:, entry:)
      game.players.find_each { |player| backdate_player(game:, player:, entry:) }
    end

    def backdate_player(game:, player:, entry:)
      player_season = player.player_seasons.find_by!(season: game.current_season)
      rng = Random.new(Zlib.crc32("#{Demo::Seeder::SEED}:history:#{player.external_id}"))

      CHECKPOINT_DAYS_AGO.each do |days_ago|
        score = checkpoint_score(player:, entry:, days_ago:, rng:)
        player_season.external_scores.create!(score:, created_at: days_ago.days.ago)
      end
    end

    def checkpoint_score(player:, entry:, days_ago:, rng:)
      entry.history_curve.call(
        current_score: player.current_score, fraction: 1.0 - (days_ago / HISTORY_HORIZON_DAYS),
        range: entry.shape.score_range, rng:
      )
    end

    def create_past_tournaments(game:, entry:)
      past_tournament_days_ago(entry.past_tournament_count).each_with_index.map do |days_ago, index|
        create_past_tournament(game:, entry:, days_ago:, index:)
      end
    end

    # entry.past_tournament_count of 3 gives [90, 60, 30] — the most recent
    # tournament always PAST_TOURNAMENT_INTERVAL_DAYS days ago, spaced apart
    # by that same interval.
    def past_tournament_days_ago(count)
      count.downto(1).map { |position| position * PAST_TOURNAMENT_INTERVAL_DAYS }
    end

    def create_past_tournament(game:, entry:, days_ago:, index:)
      formats = ::Tournament.formats.keys
      ::Tournament.create!(
        game:, name: "#{entry.name} Regional ##{index + 1}", external_id: past_external_id(index + 1),
        starting_date: days_ago.days.ago.to_date,
        country: PAST_TOURNAMENT_COUNTRIES[index % PAST_TOURNAMENT_COUNTRIES.length],
        format: formats[index % formats.length]
      )
    end

    def past_external_id(position)
      "/tournaments/past-#{position}"
    end

    def import_results(tournaments:, entry:)
      tournaments.each do |tournament|
        ExternalData::Synthetic::ImportResultsJob.perform_now(
          tournament_id: tournament.id, seed: Demo::Seeder::SEED, shape: entry.shape
        )
      end
    end

  end

end
