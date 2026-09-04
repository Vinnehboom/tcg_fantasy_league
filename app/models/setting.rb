class Setting < ApplicationRecord

  include Settingable

  # optional: true since a Game-owned row also sets settingable_id and would
  # otherwise fail Rails' "must exist" check.
  belongs_to :season, foreign_key: :settingable_id, inverse_of: :setting, optional: true

  before_validation :assign_settingable_type

  def self.for(season:)
    super(settingable: season)
  end

  # Carry-forward-only: the nearest *prior* season of the same game, never a
  # later one. A past season's settings must be a direct lookup, not a
  # reconstruction from override history, so this only ever looks backward.
  # An open season (null end_date) never satisfies the WHERE clause's `<`
  # below, so it can never be a candidate here; NULLS LAST is belt-and-braces
  # against that WHERE clause ever widening (Postgres sorts NULL first on a
  # DESC order by default).
  #
  # Looks up Season first, casting Season.id (always a valid integer) to
  # text rather than casting settingable_id (a Game-owned row's id is
  # non-numeric, e.g. 'PTCG') to bigint — the untrusted column is never
  # cast, so a query planner that evaluates the cast before the type filter
  # can't blow up on a Game-owned row.
  def self.nearest_prior(season)
    candidate_season = Season.where(game_id: season.game_id, end_date: ...season.start_date)
                             .where(
                               'id::text IN (SELECT settingable_id FROM settings WHERE settingable_type = ?)',
                               'Season'
                             )
                             .order('end_date DESC NULLS LAST')
                             .first
    candidate_season && find_by(settingable: candidate_season)
  end
  private_class_method :nearest_prior

  private

  # Fills in settingable_type for the season=/season: writer. ||= so a
  # Game-owned row's own value isn't clobbered.
  def assign_settingable_type
    self.settingable_type ||= 'Season'
  end

end
