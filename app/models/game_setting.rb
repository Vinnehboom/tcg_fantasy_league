class GameSetting < ApplicationRecord

  include Settingable

  belongs_to :season, foreign_key: :settingable_id, inverse_of: :game_setting
  has_one :game, through: :season

  before_validation :assign_settingable_type

  def self.for(season:)
    super(settingable: season)
  end

  # Carry-forward-only: the nearest *prior* season of the same game, never a
  # later one. A past season's settings must be a direct lookup, not a
  # reconstruction from override history, so this only ever looks backward.
  def self.nearest_prior(season)
    joins(:season)
      .where(season: { game_id: season.game_id, end_date: ...season.start_date })
      .order('season.end_date DESC')
      .first
  end
  private_class_method :nearest_prior

  private

  # `season=`/`season:` (the public interface kept for callers) only sets
  # settingable_id, not settingable_type — GameSetting only ever means
  # Season, so this fills in the other half of the polymorphic pair itself.
  def assign_settingable_type
    self.settingable_type = 'Season'
  end

end
