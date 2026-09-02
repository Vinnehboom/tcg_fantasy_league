class ExternalScore < ApplicationRecord

  belongs_to :player_season
  has_one :player, through: :player_season

  # external_scores has no player_id column, so the ranking subquery joins
  # player_seasons to partition by player. It carries score and created_at
  # itself, so the rn = 1 filter keeps one row for each player.
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

  validates :score, presence: true

end
