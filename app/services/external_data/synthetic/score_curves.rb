module ExternalData

  module Synthetic

    # Pure score-shape formulas, injected into ExternalData::Synthetic::Adapter
    # rather than branched on there — see H-9's Decisions D4. Each takes the
    # player's rank (0 = top), the field size, and the target range, and
    # returns a raw (unjittered, unclamped) score.
    module ScoreCurves

      # How steeply the ladder curve rewards rank 0 over the rest of the
      # field — bigger means a sharper drop-off from the top.
      LADDER_STEEPNESS = 2.2

      # The logit curve is undefined at the exact edges of 0 and 1, so the
      # ELO band clamps its input fraction to this range instead.
      ELO_BAND_MIN_FRACTION = 0.02
      ELO_BAND_MAX_FRACTION = 0.98
      ELO_BAND_FRACTION_SPAN = ELO_BAND_MAX_FRACTION - ELO_BAND_MIN_FRACTION

      # A ladder that rewards the top of the field steeply and tails off
      # toward the bottom — championship points, not a bounded rating.
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

    end

  end

end
