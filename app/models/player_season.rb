class PlayerSeason < ApplicationRecord

  belongs_to :player
  belongs_to :season
  has_many :external_scores, dependent: :destroy
  validates :player_id, uniqueness: { scope: :season_id }

end
