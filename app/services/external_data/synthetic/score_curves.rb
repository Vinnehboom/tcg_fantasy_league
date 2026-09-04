module ExternalData

  module Synthetic

    # Pure score-shape formulas, injected into ExternalData::Synthetic::Adapter
    # rather than branched on there — see H-9's Decisions D4. Each takes the
    # player's rank (0 = top), the field size, and the target range, and
    # returns a raw (unjittered, unclamped) score.
    module ScoreCurves

      # A ladder that rewards the top of the field steeply and tails off
      # toward the bottom — championship points, not a bounded rating.
      LADDER = lambda do |index:, count:, range:|
        fraction = (count - index).to_f / count
        range.min + ((range.max - range.min) * (fraction**2.2))
      end

      # A bounded band concentrated around its own midpoint — an ELO-style
      # rating, where most of the field sits close to average.
      ELO_BAND = lambda do |index:, count:, range:|
        midpoint = (range.min + range.max) / 2.0
        spread = (range.max - midpoint) / Math.log(0.98 / 0.02)
        fraction = ((index.to_f / (count - 1)) * 0.96) + 0.02
        midpoint + (spread * Math.log(fraction / (1 - fraction)))
      end

    end

  end

end
