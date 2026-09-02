class PlayerSeason < ApplicationRecord

  belongs_to :player
  belongs_to :season
  has_many :external_scores, dependent: :destroy
  has_many :player_season_modifiers, dependent: :destroy
  has_many :score_modifiers, through: :player_season_modifiers
  validates :player_id, uniqueness: { scope: :season_id }

end
