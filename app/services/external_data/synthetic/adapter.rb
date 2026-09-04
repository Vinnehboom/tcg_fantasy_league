module ExternalData

  module Synthetic

    # A game-agnostic adapter that makes no HTTP request. It answers the same
    # four methods as ExternalData::Pokemon::Tcg::Adapter, with plausible,
    # seed-reproducible data instead of a live fetch — see H-9. Nothing here
    # names a specific game: the caller injects the score shape (see Shape)
    # and the seed.
    class Adapter

      DEFAULT_SEED = 924_601
      DEFAULT_SHAPE = Shape.new(score_range: (200..1600), score_curve: ScoreCurves::LADDER,
                                player_count: 64, tournament_count: 3)
      MIN_DAYS_OUT = 7
      RESULTS_PER_TOURNAMENT = 32
      JITTER_SPAN = 12
      FIELD_SIZE_JITTER_SPAN = 200

      def initialize(game:, seed: DEFAULT_SEED, shape: DEFAULT_SHAPE, season: game.current_season)
        raise_outside_the_sandbox!
        @seed = seed
        @score_range = shape.score_range
        @score_curve = shape.score_curve
        @player_count = shape.player_count
        @tournament_count = shape.tournament_count
        @season = season
      end

      def players
        with_deterministic_faker(seed) { Array.new(player_count) { |index| build_player(index) } }
      end

      def upcoming_tournaments
        with_deterministic_faker(seed) { Array.new(tournament_count) { |index| build_tournament(index) } }
      end

      def results(tournament:)
        digest = tournament_digest(tournament)
        with_deterministic_faker(digest) { build_results(digest) }
      end

      def field_size(tournament:)
        digest = tournament_digest(tournament)
        results_count + 1 + (digest % FIELD_SIZE_JITTER_SPAN) # +1: always strictly above results_count
      end

      private

      attr_reader :seed, :score_range, :score_curve, :player_count, :tournament_count, :season

      # A demo dataset written into the production database is not
      # reversible, so this checks independently of every other guard in the
      # ticket (the adapter-selection config, Demo::Seeder, Demo::Reset).
      def raise_outside_the_sandbox!
        return unless Rails.env.production?

        raise ExternalData::Exception.new(
          'Synthetic adapter invalid in production',
          "#{self.class.name} must never run against the production database"
        )
      end

      def with_deterministic_faker(seed_value)
        previous_random = Faker::Config.random
        Faker::Config.random = Random.new(seed_value)
        yield
      ensure
        Faker::Config.random = previous_random
      end

      def build_player(index)
        ExternalData::Player.new(
          attributes: {
            external_id: "/players/#{index}",
            name: Faker::Name.name,
            country: Faker::Address.country_code,
            external_points: score_for(index),
            season:
          }
        )
      end

      def score_for(index)
        raw = score_curve.call(index:, count: player_count, range: score_range)
        (raw + jitter_for(index)).round.clamp(score_range.min, score_range.max)
      end

      def jitter_for(index)
        Random.new(Zlib.crc32("#{seed}:jitter:#{index}")).rand(-JITTER_SPAN..JITTER_SPAN)
      end

      def build_tournament(index)
        ExternalData::Tournament.new(
          attributes: {
            external_id: "/tournaments/#{index}",
            name: Faker::Game.title,
            country: Faker::Address.country_code,
            starting_date: starting_date_for(index),
            format: ::Tournament.formats.keys.sample(random: Random.new(Zlib.crc32("#{seed}:format:#{index}")))
          }
        )
      end

      def starting_date_for(index)
        (MIN_DAYS_OUT + (index * 5)).days.from_now.to_date
      end

      def results_count
        [player_count, RESULTS_PER_TOURNAMENT].min
      end

      def tournament_digest(tournament)
        Zlib.crc32("#{seed}:#{tournament.external_id}")
      end

      def build_results(digest)
        rng = Random.new(digest)
        chosen_indices = (0...player_count).to_a.sample(results_count, random: rng)
        chosen_indices.map.with_index(1) { |player_index, placement| build_result(player_index:, placement:) }
      end

      def build_result(player_index:, placement:)
        ExternalData::Result.new(
          attributes: {
            player_external_id: "/players/#{player_index}",
            player_name: Faker::Name.name,
            player_country: Faker::Address.country_code,
            placement:
          }
        )
      end

    end

  end

end
