class ExternalScore < ApplicationRecord

  belongs_to :player_season
  has_one :player, through: :player_season

  validates :score, presence: true

end
