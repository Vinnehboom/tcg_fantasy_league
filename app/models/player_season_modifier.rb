class PlayerSeasonModifier < ApplicationRecord

  belongs_to :player_season
  belongs_to :score_modifier

  validates :player_season_id, uniqueness: { scope: :score_modifier_id }

  # ScoreModifier carries no default_scope, so #score_modifier above already
  # resolves a discarded modifier fine on its own - this join row survives a
  # discard on purpose (discard doesn't cascade-destroy it). Display code
  # that needs the discarded record's own name reads it through the plain
  # association, same as any other case.

end
