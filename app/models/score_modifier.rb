class ScoreModifier < ApplicationRecord

  validates :name, presence: true
  validates :value, presence: true

  def apply(score)
    raise NotImplementedError, "#{self.class} must implement #apply"
  end

end
