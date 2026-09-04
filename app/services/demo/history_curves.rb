module Demo

  # How a player's rating moves over the historical checkpoints Demo::History
  # backdates (H-9, Decisions D5) — a second per-game lambda, alongside each
  # game's current-score curve in its Shape. Each takes the player's current
  # score, a fraction (0 = the oldest checkpoint, 1 = now), the score range,
  # and a per-player deterministic Random, and returns that checkpoint's
  # score — jittered, but never String#hash: the caller seeds the Random.
  module HistoryCurves

    ACCUMULATING_JITTER = (-8..8)
    WANDERING_JITTER = (-40..40)

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
