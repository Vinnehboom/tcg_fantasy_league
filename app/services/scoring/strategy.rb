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
  # deep tiers go. A tournament's max_tier (from its field_size) caps how
  # deep any placement can score, so a big event's deepest bracket doesn't
  # score infinitely small — everyone past it floors out at the same
  # base_score as the deepest real bracket.
  class Strategy

    DEFAULT_BASE_POINTS = 100
    DEFAULT_DECAY = 0.65

    # A list of size-class lower bounds, not a fixed S/M/L/XL enum, so a
    # future band (an XS below the smallest row, an XXL above the largest)
    # can be added by inserting a row rather than editing existing ones
    # (Checkpoint 1, Q3). Each field_size gets the multiplier of the
    # highest band whose minimum it clears.
    DEFAULT_SIZE_CLASSES = [
      { minimum_field_size: 0, multiplier: 1 },    # S
      { minimum_field_size: 500, multiplier: 2 },  # M
      { minimum_field_size: 1500, multiplier: 4 }, # L
      { minimum_field_size: 3000, multiplier: 8 }  # XL
    ].freeze

    # Composition root: resolves tunables from data instead of hardcoding
    # them here, in the order season's own Setting -> the season's game's
    # default Setting -> these class's own code constants (Checkpoint 2
    # sign-off, D5 as corrected for the Game-owned-default-row design).
    # Merge is per-key, not whole-row — a season row that only overrides
    # e.g. base_points still falls through to the game default (or code
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
        { minimum_field_size:, multiplier: } if minimum_field_size && multiplier
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
    # both. C-7 only exposes the flag; there's no admin Settings/Seasons UI
    # yet to hang a banner on (D9).
    def using_default_config?
      @using_default_config
    end

    def base_score(placement:, field_size:)
      raise MissingFieldSizeError if field_size.nil?

      capped_tier = [tier(placement), max_tier(field_size)].min
      [1, (base_points * (decay**level(capped_tier))).round].max
    end

    # Duck-typed: `result` need only respond to `placement` and
    # `tournament.field_size` (field_size lives on Tournament, not Result —
    # Checkpoint 1 correction #2). Whole-number points: base_score is
    # already a rounded Integer, and every multiplier is an Integer too.
    def points_for(result:)
      field_size = result.tournament.field_size

      base_score(placement: result.placement, field_size:) * multiplier(field_size)
    end

    private

    attr_reader :base_points, :decay, :size_classes

    def multiplier(field_size)
      size_classes
        .select { |band| band[:minimum_field_size] <= field_size }
        .max_by { |band| band[:minimum_field_size] }
        .fetch(:multiplier)
    end

    # Placement has no numericality validation yet (C-12), so 0/negatives
    # are storable today — clamp instead of trusting the raw value.
    def tier(placement)
      smallest_power_of_two_at_least(placement.to_i.clamp(1..))
    end

    def level(tier)
      Math.log2(tier).round
    end

    def max_tier(field_size)
      smallest_power_of_two_at_least((field_size / 2.0).ceil)
    end

    def smallest_power_of_two_at_least(number)
      return 1 if number <= 1

      2**Math.log2(number).ceil
    end

  end

end
