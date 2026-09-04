class PlayerSeason < ApplicationRecord

  belongs_to :player
  belongs_to :season
  has_many :external_scores, dependent: :destroy
  has_many :player_season_modifiers, dependent: :destroy
  has_many :score_modifiers, through: :player_season_modifiers
  validates :player_id, uniqueness: { scope: :season_id }

  # The attach form on the player's page must not offer a modifier this
  # player_season already has - the join has a uniqueness constraint on
  # [player_season_id, score_modifier_id], so picking one again would fail.
  def available_score_modifiers
    ScoreModifier.kept.where.not(id: score_modifier_ids).order(:name)
  end

end
