class ExternalScore < ApplicationRecord

  belongs_to :player_season
  has_one :player, through: :player_season

  # external_scores has no player_id column, so the ranking subquery joins
  # player_seasons to partition by player.
  # The rows are projections meant for a join, not usable ExternalScore
  # records: they carry no id, so reading any unselected attribute or
  # association raises ActiveModel::MissingAttributeError.
  scope :latest_per_player, lambda {
    select('ranked_scores.player_id, ranked_scores.score, ranked_scores.created_at')
      .from(<<~SQL.squish)
        (
          SELECT player_seasons.player_id,
                 external_scores.score,
                 external_scores.created_at,
                 ROW_NUMBER() OVER (
                   PARTITION BY player_seasons.player_id
                   ORDER BY external_scores.created_at DESC, external_scores.id DESC
                 ) AS rn
          FROM external_scores
          JOIN player_seasons ON player_seasons.id = external_scores.player_season_id
        ) ranked_scores
      SQL
      .where(ranked_scores: { rn: 1 })
  }

  scope :latest_per_player_season, lambda { |player_season_ids|
    where(player_season_id: player_season_ids)
      .select('DISTINCT ON (player_season_id) player_season_id, score')
      .order('player_season_id, created_at DESC, id DESC')
  }

  validates :score, presence: true

end
