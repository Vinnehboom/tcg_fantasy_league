class ScoreModifier < ApplicationRecord

  has_many :player_season_modifiers, dependent: :destroy
  has_many :player_seasons, through: :player_season_modifiers

  validates :name, presence: true
  validates :value, presence: true

  def apply(score)
    raise NotImplementedError, "#{self.class} must implement #apply"
  end

end
