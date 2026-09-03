module Scoring

  # Turns a Result's placement into points. Held and queried across many
  # results for a season, so this is a plain PORO (not an
  # initialize+#call service) per the style guide's carve-out for a
  # long-lived calculator.
  #
  # Placements are bracketed into tiers (1st and 2nd are their own tiers;
  # 3rd-4th share T4, 5th-8th share T8, etc — the smallest power of 2 at
  # least as big as the placement), and a tier's base score decays
  # geometrically the deeper it is, bounded below at 1 regardless of how
  # deep tiers go. Each size class's own max_tier_field_size caps how deep
  # any placement in that class can score, so the class's deepest bracket
  # doesn't score infinitely small — everyone past it floors out at the
  # same base_score as that bracket.
  #
  # max_tier is a property of the size CLASS, not of a tournament's raw
  # field_size, deliberately: an earlier version derived it straight from
  # field_size, which made base_score strictly non-increasing as
  # field_size grew (every extra entrant deepens the bracket structure a
  # touch more), while the multiplier only jumps at the handful of class
  # boundaries — two step functions moving on different schedules, so the
  # multiplier didn't reliably cover base_score's drop between them.
  # Concretely: 2nd place in a 2-player field scored 100, a 4-player field
  # scored 65, same size class either way. Pinning max_tier per class
  # instead makes base_score flat across an entire class for a fixed
  # placement, leaving only the (already monotonic) multiplier to vary
  # between classes.
  class Strategy

    DEFAULT_BASE_POINTS = 100
    DEFAULT_DECAY = 0.65

    # A list of size-class lower bounds, not a fixed S/M/L/XL enum, so a
    # future band (an XS below the smallest row, an XXL above the largest)
    # can be added by inserting a row rather than editing existing ones.
    # Each field_size gets the multiplier (and max_tier_field_size — see
    # the class comment above) of the highest band whose minimum it
    # clears — or, if a configured list has no band starting at 0, the
    # lowest band it has (see #band_for below), so a field_size under
    # every configured minimum still scores something sane instead of
    # raising.
    #
    # max_tier_field_size is chosen so each class's max_tier is at most
    # one bracket-level deeper than the previous class's — with a 2x
    # multiplier jump between every class and 0.65 decay per level, one
    # extra level of decay (a ~1.54x drop) is always covered by that 2x,
    # so points_for is guaranteed non-decreasing in field_size for a fixed
    # placement (see the monotonicity spec). It does NOT track each
    # class's own field_size range one-for-one — XL's value is pinned to
    # 3000 specifically to keep the ticket's worked example unchanged; the
    # others are chosen backward from XL to keep every step to one level.
    DEFAULT_SIZE_CLASSES = [
      { minimum_field_size: 0, multiplier: 1, max_tier_field_size: 499 },     # S
      { minimum_field_size: 500, multiplier: 2, max_tier_field_size: 999 },   # M
      { minimum_field_size: 1500, multiplier: 4, max_tier_field_size: 1999 }, # L
      { minimum_field_size: 3000, multiplier: 8, max_tier_field_size: 3000 } # XL
    ].freeze

    # Composition root: resolves tunables from data instead of hardcoding
    # them here, in the order season's own Setting -> the season's game's
    # default Setting -> these class's own code constants. Merge is
    # per-key, not whole-row — a season row that only overrides e.g.
    # base_points still falls through to the game default (or code
    # constants) for decay/size_classes, rather than losing them entirely.
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

    # Coerces each band independently and drops any that don't parse,
    # rather than discarding the whole list for one bad row. Falls back to
    # the code default list only when nothing usable survives.
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

    # True when no season Setting (the season's own row, or one carried
    # forward from a nearest prior season) supplied any scoring config —
    # i.e. values came from the game's default Setting, code constants, or
    # both. Only exposes the flag; there's no admin Settings/Seasons UI yet
    # to hang a banner on.
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
    # Whole-number points: base_score is already a rounded Integer, and
    # every multiplier is an Integer too.
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

    # tier is always an exact power of 2 (it only ever comes from
    # smallest_power_of_two_at_least below), so its bit length gives the
    # exponent directly — exact, and avoids float log2's imprecision.
    def level(tier)
      tier.bit_length - 1
    end

    # Derived from the field_size's size CLASS, not the raw field_size —
    # see the class comment above for why. Two tournaments in the same
    # class always share the same max_tier, regardless of their own exact
    # field_size.
    def max_tier(field_size)
      reference_field_size = band_for(field_size).fetch(:max_tier_field_size)
      smallest_power_of_two_at_least((reference_field_size / 2.0).ceil)
    end

    # Falls back to the lowest configured band when field_size is under
    # every configured minimum (e.g. a configured list starting at 500
    # with no explicit 0-minimum row) — the alternative, raising, would
    # turn a perfectly normal small-field tournament into a 500 error.
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
