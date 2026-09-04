class Multiplier < ScoreModifier

  # allow_nil: the base class's own `numericality: true` already reports a
  # missing value - this validation only has something new to say once a
  # value is actually present.
  # A multiplier of zero or less wipes out or reverses the score it touches.
  validates :value, numericality: { greater_than: 0, allow_nil: true }

  def apply(score)
    score * value
  end

end
