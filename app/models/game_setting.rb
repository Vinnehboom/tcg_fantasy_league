class GameSetting < ApplicationRecord

  belongs_to :season
  has_one :game, through: :season

  validates :settings, presence: true
  validates :season_id, uniqueness: true

end
