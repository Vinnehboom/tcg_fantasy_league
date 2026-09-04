class PlayerSeasonModifier < ApplicationRecord

  belongs_to :player_season
  belongs_to :score_modifier

  validates :player_season_id, uniqueness: { scope: :score_modifier_id }

end
