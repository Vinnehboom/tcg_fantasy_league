module Demo

  # Every score-shape lambda the demo dataset uses (H-9 review round 2):
  # each game's Shape injects a current-score curve (LADDER, ELO_BAND), and
  # Demo::History injects a history curve (ACCUMULATING, WANDERING) for the
  # same game's backdated checkpoints. Merged into one module because both
  # halves are the same kind of thing — a pure formula, injected into a
  # caller rather than branched on there — and the caller (an adapter, or
  # Demo::History) takes whichever lambda it is given without caring where
  # it came from.
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

    # A ladder that rewards the top of the field steeply and tails off
    # toward the bottom — championship points, not a bounded rating. Takes
    # the player's rank (0 = top), the field size, and the target range,
    # and returns a raw (unjittered, unclamped) score.
    LADDER = lambda do |index:, count:, range:|
      fraction = (count - index).to_f / count
      range.min + ((range.max - range.min) * (fraction**LADDER_STEEPNESS))
    end

    # A bounded band concentrated around its own midpoint — an ELO-style
    # rating, where most of the field sits close to average. Rank 0 (the
    # top) maps to the highest fraction, same convention as LADDER.
    ELO_BAND = lambda do |index:, count:, range:|
      midpoint = (range.min + range.max) / 2.0
      next midpoint if count <= 1

      spread = (range.max - midpoint) / Math.log(ELO_BAND_MAX_FRACTION / ELO_BAND_MIN_FRACTION)
      fraction = (((count - index).to_f / count) * ELO_BAND_FRACTION_SPAN) + ELO_BAND_MIN_FRACTION
      midpoint + (spread * Math.log(fraction / (1 - fraction)))
    end

    # How a player's rating moves over the historical checkpoints
    # Demo::History backdates. Takes the player's current score, a fraction
    # (0 = the oldest checkpoint, 1 = now), the score range, and a
    # per-player deterministic Random, and returns that checkpoint's score
    # — jittered, but never String#hash: the caller seeds the Random.
    #
    # Championship points only accumulate, so history rises monotonically
    # toward the current value as the fraction approaches 1.
    ACCUMULATING = lambda do |current_score:, fraction:, range:, rng:|
      raw = range.min + ((current_score - range.min) * fraction)
      (raw + rng.rand(ACCUMULATING_JITTER)).round.clamp(range.min, current_score)
    end

    # An ELO rating moves both ways, so history wanders around the current
    # value instead of climbing toward it — more so the further back in time.
    WANDERING = lambda do |current_score:, fraction:, range:, rng:|
      drift = rng.rand(WANDERING_JITTER) * (1 - fraction)
      (current_score + drift).round.clamp(range.min, range.max)
    end

  end

end
