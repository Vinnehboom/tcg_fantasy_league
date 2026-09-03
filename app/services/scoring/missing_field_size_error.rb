module Scoring

  # Raised when a Strategy is asked to score a placement whose tournament
  # has no field_size on record — a programmer/data error, not something a
  # caller should silently work around with a default size class.
  class MissingFieldSizeError < StandardError

  end

end
