module Scoring

  # Contract every Scoring::*Strategy implements: `.for(season:)` resolves
  # a configured instance for a season, `#points_for(result:)` turns a
  # placement Result into points, and `#using_default_config?` reports
  # whether the season supplied its own tuning.
  #
  # TieredPlacementStrategy: a tier from the placement (bracketed to powers
  # of 2), then geometric decay by tier depth, capped by the tournament's
  # size class. max_tier depends on the size class, not the raw field_size,
  # so points never decrease as field_size grows for a fixed placement (see
  # the monotonicity spec). PORO per the style guide's carve-out for a
  # long-lived, queried-many-times calculator.
  class TieredPlacementStrategy

    DEFAULT_BASE_POINTS = 100
    DEFAULT_DECAY = 0.65

    # Bands, not a fixed enum, so a new one can be inserted without editing
    # existing ones. max_tier_field_size values keep points from decreasing
    # as field_size grows; XL is pinned to 3000 to match the ticket's
    # worked example.
    DEFAULT_SIZE_CLASSES = [
      { minimum_field_size: 0, multiplier: 1, max_tier_field_size: 499 },     # S
      { minimum_field_size: 500, multiplier: 2, max_tier_field_size: 999 },   # M
      { minimum_field_size: 1500, multiplier: 4, max_tier_field_size: 1999 }, # L
      { minimum_field_size: 3000, multiplier: 8, max_tier_field_size: 3000 } # XL
    ].freeze

    # Tunables merge per-key, not whole-row: season's own Setting, then the
    # game's default, then code constants.
    def self.for(season:)
      raise MissingSeasonError if season.nil?

      own_config = scoring_config(Setting.for(season:))
      merged = scoring_config(season.game.default_setting).merge(own_config)

      new(
        base_points: coerce_integer(merged['base_points'], default: DEFAULT_BASE_POINTS),
        decay: coerce_float(merged['decay'], default: DEFAULT_DECAY),
        size_classes: coerce_size_classes(merged['size_classes']),
        using_default_config: own_config.blank?
      )
    end

    def self.scoring_config(setting)
      setting&.settings&.dig('scoring') || {}
    end
    private_class_method :scoring_config

    def self.coerce_integer(value, default:)
      Integer(value, exception: false) || default
    end
    private_class_method :coerce_integer

    def self.coerce_float(value, default:)
      Float(value, exception: false) || default
    end
    private_class_method :coerce_float

    # Coerces each band independently, dropping only the ones that don't
    # parse, rather than discarding the whole list for one bad row.
    def self.coerce_size_classes(value)
      return DEFAULT_SIZE_CLASSES if value.blank?

      value.filter_map do |band|
        minimum_field_size = coerce_integer(band['minimum_field_size'], default: nil)
        multiplier = coerce_integer(band['multiplier'], default: nil)
        max_tier_field_size = coerce_integer(band['max_tier_field_size'], default: nil)
        next unless minimum_field_size && multiplier && max_tier_field_size

        { minimum_field_size:, multiplier:, max_tier_field_size: }
      end.presence || DEFAULT_SIZE_CLASSES
    end
    private_class_method :coerce_size_classes

    def initialize(base_points: DEFAULT_BASE_POINTS, decay: DEFAULT_DECAY, size_classes: DEFAULT_SIZE_CLASSES,
                   using_default_config: true)
      @base_points = base_points
      @decay = decay
      @size_classes = size_classes
      @using_default_config = using_default_config
    end

    def using_default_config?
      @using_default_config
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

    attr_reader :base_points, :decay, :size_classes

    def multiplier(field_size)
      band_for(field_size).fetch(:multiplier)
    end

    # Placement has no numericality validation yet (C-12), so 0/negatives
    # are storable today — clamp instead of trusting the raw value.
    def tier(placement)
      smallest_power_of_two_at_least(placement.to_i.clamp(1..))
    end

    # tier is always an exact power of 2, so its bit length gives the
    # exponent directly — exact, unlike float log2 right at a power of 2.
    def level(tier)
      tier.bit_length - 1
    end

    # Depends on field_size's size class, not the raw field_size — see class comment.
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
