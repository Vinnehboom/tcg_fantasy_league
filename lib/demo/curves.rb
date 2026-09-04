module Demo

  module Curves

    # How steeply the ladder curve rewards rank 0 over the rest of the
    # field — bigger means a sharper drop-off from the top.
    LADDER_STEEPNESS = 2.2

    # The logit curve is undefined at the exact edges of 0 and 1, so the
    # ELO band clamps its input fraction to this range instead.
    ELO_BAND_MIN_FRACTION = 0.02
    ELO_BAND_MAX_FRACTION = 0.98
    ELO_BAND_FRACTION_SPAN = ELO_BAND_MAX_FRACTION - ELO_BAND_MIN_FRACTION

    ACCUMULATING_JITTER = (-8..8)
    WANDERING_JITTER = (-40..40)

    # Rank 0 = top of the field.
    LADDER = lambda do |index:, count:, range:|
      fraction = (count - index).to_f / count
      range.min + ((range.max - range.min) * (fraction**LADDER_STEEPNESS))
    end

    # Rank 0 = top of the field, same convention as LADDER.
    ELO_BAND = lambda do |index:, count:, range:|
      midpoint = (range.min + range.max) / 2.0
      next midpoint if count <= 1

      spread = (range.max - midpoint) / Math.log(ELO_BAND_MAX_FRACTION / ELO_BAND_MIN_FRACTION)
      fraction = (((count - index).to_f / count) * ELO_BAND_FRACTION_SPAN) + ELO_BAND_MIN_FRACTION
      midpoint + (spread * Math.log(fraction / (1 - fraction)))
    end

    # Championship points only accumulate, so history rises monotonically
    # toward the current value as fraction (0 = oldest, 1 = now) approaches 1.
    ACCUMULATING = lambda do |current_score:, fraction:, range:, rng:|
      raw = range.min + ((current_score - range.min) * fraction)
      (raw + rng.rand(ACCUMULATING_JITTER)).round.clamp(range.min, current_score)
    end

    # An ELO rating moves both ways, so history wanders around the current
    # value instead of climbing toward it.
    WANDERING = lambda do |current_score:, fraction:, range:, rng:|
      drift = rng.rand(WANDERING_JITTER) * (1 - fraction)
      (current_score + drift).round.clamp(range.min, range.max)
    end

  end

end
