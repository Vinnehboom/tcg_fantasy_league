module Scoring

  # Raised when Strategy.for(season:) is asked to resolve config for a nil
  # season — a programmer/data error, same posture as MissingFieldSizeError:
  # season resolution belongs to the caller (a covering Season should
  # always exist once Season.default_for has backstopped every game), so a
  # missing one here means something upstream is broken, not something to
  # paper over with a silent fallback.
  class MissingSeasonError < StandardError

  end

end
