class Bonus < ScoreModifier

  def apply(score)
    score + value
  end

end
