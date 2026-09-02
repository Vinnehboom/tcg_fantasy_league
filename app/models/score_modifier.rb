class ScoreModifier < ApplicationRecord

  validates :name, presence: true
  validates :value, presence: true
  has_many :player_season_modifiers, dependent: :destroy
  has_many :player_seasons, through: :player_season_modifiers

  def apply(score)
    raise NotImplementedError, "#{self.class} must implement #apply"
  end

end
