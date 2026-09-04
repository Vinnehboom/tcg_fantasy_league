class Multiplier < ScoreModifier

  # A multiplier of zero or less wipes out or reverses the score it touches.
  validates :value, numericality: { greater_than: 0 }

  def apply(score)
    score * value
  end

end
