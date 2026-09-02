class ExternalScore < ApplicationRecord

  belongs_to :player_season
  validates :score, presence: true

end
