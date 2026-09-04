class Multiplier < ScoreModifier

  validates :value, numericality: { greater_than: 0, allow_nil: true }

  def apply(score)
    score * value
  end

end
