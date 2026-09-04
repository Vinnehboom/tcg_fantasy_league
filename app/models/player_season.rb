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
  #
  # Takes the closed, kept pool as an argument rather than querying for it:
  # a player's page calls this once per player_season row, and the kept
  # family is a small, shared list - querying it fresh per row is needless
  # repeated work over the same handful of records.
  def available_score_modifiers(kept_score_modifiers = ScoreModifier.kept.order(:name))
    attached_ids = player_season_modifiers.map(&:score_modifier_id)
    kept_score_modifiers.reject { |score_modifier| attached_ids.include?(score_modifier.id) }
  end

end
