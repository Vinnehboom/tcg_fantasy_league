class GameSetting < ApplicationRecord

  belongs_to :season
  has_one :game, through: :season

  validates :settings, presence: true
  validates :season_id, uniqueness: true

  def self.for(season:)
    find_by(season_id: season.id) || nearest_prior(season)
  end

  def self.nearest_prior(season)
    joins(:season)
      .where(season: { game_id: season.game_id, end_date: ...season.start_date })
      .order('season.end_date DESC')
      .first
  end
  private_class_method :nearest_prior

end
