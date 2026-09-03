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

    def initialize(base_points: DEFAULT_BASE_POINTS, decay: DEFAULT_DECAY)
      @base_points = base_points
      @decay = decay
    end

    def base_score(placement:, field_size:)
      raise MissingFieldSizeError if field_size.nil?

      capped_tier = [tier(placement), max_tier(field_size)].min
      [1, (base_points * (decay**level(capped_tier))).round].max
    end

    private

    attr_reader :base_points, :decay

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
