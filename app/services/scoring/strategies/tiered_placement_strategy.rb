module Scoring

  module Strategies

    # A tier from the placement (bracketed to powers of 2), decayed
    # geometrically by tier depth and capped by the tournament's size class —
    # max_tier depends on the size class, not the raw field_size, so points
    # never decrease as field_size grows for a fixed placement under the
    # shipped DEFAULT_SIZE_CLASSES band gaps (see the monotonicity spec); an
    # arbitrary custom config isn't guaranteed to preserve this. `#base_score`
    # is public too, but it's this class's own tier/decay mechanics, not part
    # of the Scoring::*Strategy contract — a different Strategy need not have one.
    class TieredPlacementStrategy

      DEFAULT_BASE_POINTS = 100
      DEFAULT_DECAY = 0.65

      # Bands, not a fixed enum, so a new one can be inserted without editing
      # existing ones. Each max_tier_field_size is chosen so max_tier lands
      # exactly one bracket level below the class above it
      # (256/512/1024/2048) — that one-level gap is what keeps points from
      # decreasing as field_size grows.
      DEFAULT_SIZE_CLASSES = [
        { minimum_field_size: 0, multiplier: 1, max_tier_field_size: 499 },     # S
        { minimum_field_size: 500, multiplier: 2, max_tier_field_size: 999 },   # M
        { minimum_field_size: 1500, multiplier: 4, max_tier_field_size: 1999 }, # L
        { minimum_field_size: 3000, multiplier: 8, max_tier_field_size: 3000 } # XL
      ].freeze

      def self.for(season:)
        raise MissingSeasonError if season.nil?

        own_config = config_for(Setting.for(season:))
        config = config_for(season.game.default_setting).merge(own_config)

        new(
          base_points: config.fetch('base_points', DEFAULT_BASE_POINTS),
          decay: config.fetch('decay', DEFAULT_DECAY),
          size_classes: config.fetch('size_classes', DEFAULT_SIZE_CLASSES),
          using_default_config: own_config.blank?
        )
      end

      def self.config_for(setting)
        raw = setting&.settings&.dig('scoring') || {}

        {
          'base_points' => coerce_integer(raw['base_points'], range: 1..),
          'decay' => coerce_float(raw['decay'], range: 0.0..1.0),
          'size_classes' => coerce_size_classes(raw['size_classes'])
        }.compact
      end

      # nil on a parse failure, not the range's own bound, so #config_for's
      # `.compact` can tell "invalid" apart from "validly present" and omit
      # the key entirely rather than pin it to a clamped guess.
      def self.coerce_integer(value, range:)
        Integer(value, exception: false)&.clamp(range)
      end

      def self.coerce_float(value, range:)
        Float(value, exception: false)&.clamp(range)
      end

      # Drops only the bands that fail to parse; returns nil (not the
      # default list) when nothing survives, so #config_for's `.compact`
      # omits the key entirely instead of keeping an empty list. Also nil
      # for a non-Array value (e.g. a Hash or String in the settings JSON),
      # rather than raising deeper in Array-shaped per-band logic.
      def self.coerce_size_classes(value)
        return nil unless value.is_a?(Array)

        value.filter_map do |band|
          next unless band.is_a?(Hash)

          minimum_field_size = coerce_integer(band['minimum_field_size'], range: 0..)
          multiplier = coerce_integer(band['multiplier'], range: 1..)
          max_tier_field_size = coerce_integer(band['max_tier_field_size'], range: 1..)
          next unless minimum_field_size && multiplier && max_tier_field_size

          { minimum_field_size:, multiplier:, max_tier_field_size: }
        end.presence
      end
      private_class_method :config_for, :coerce_integer, :coerce_float, :coerce_size_classes

      def initialize(base_points: DEFAULT_BASE_POINTS, decay: DEFAULT_DECAY, size_classes: DEFAULT_SIZE_CLASSES,
                     using_default_config: true)
        @base_points = base_points
        @decay = decay
        @size_classes = size_classes
        @using_default_config = using_default_config
      end

      def using_default_config?
        using_default_config
      end

      def base_score(placement:, field_size:)
        raise MissingFieldSizeError if field_size.nil?

        capped_tier = [tier(placement), max_tier(field_size)].min
        [1, (base_points * (decay**level(capped_tier))).round].max
      end

      # Duck-typed: `result` need only respond to `placement` and
      # `tournament.field_size` (field_size lives on Tournament, not Result).
      def points_for(result:)
        field_size = result.tournament.field_size

        base_score(placement: result.placement, field_size:) * multiplier(field_size)
      end

      private

      attr_reader :base_points, :decay, :size_classes, :using_default_config

      def multiplier(field_size)
        band_for(field_size).fetch(:multiplier)
      end

      # Placement has no numericality validation yet, so 0/negatives
      # are storable today — clamp instead of trusting the raw value.
      def tier(placement)
        smallest_power_of_two_at_least(placement.to_i.clamp(1..))
      end

      # tier is always an exact power of 2, so its bit length gives the
      # exponent directly (see #smallest_power_of_two_at_least for why bit
      # length over float log2).
      def level(tier)
        tier.bit_length - 1
      end

      def max_tier(field_size)
        reference_field_size = band_for(field_size).fetch(:max_tier_field_size)
        smallest_power_of_two_at_least((reference_field_size / 2.0).ceil)
      end

      # Falls back to the lowest band if field_size is under every configured
      # minimum, rather than raising on a valid small tournament.
      def band_for(field_size)
        band = size_classes.select { |b| b[:minimum_field_size] <= field_size }
                           .max_by { |b| b[:minimum_field_size] }
        band || size_classes.min_by { |b| b[:minimum_field_size] }
      end

      # Exact integer bit-twiddling instead of float Math.log2, which isn't
      # guaranteed precise right at a power of 2.
      def smallest_power_of_two_at_least(number)
        return 1 if number <= 1

        1 << (number - 1).bit_length
      end

    end

  end

end
