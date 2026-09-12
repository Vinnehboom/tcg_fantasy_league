class PlayerSeason < ApplicationRecord

  belongs_to :player, -> { unscope(where: :suppressed_at) }, inverse_of: :player_seasons
  belongs_to :season
  has_many :external_scores, dependent: :destroy
  has_many :player_season_modifiers, dependent: :destroy
  has_many :score_modifiers, through: :player_season_modifiers
  validates :player_id, uniqueness: { scope: :season_id }

end
