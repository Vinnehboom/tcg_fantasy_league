module Scoring

  # Raised when Strategy.for(season:) gets a nil season — a data/programmer
  # error, not something to paper over with a silent fallback.
  class MissingSeasonError < StandardError

  end

end
