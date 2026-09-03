class Setting < ApplicationRecord

  include Settingable

  # optional: true since a Game-owned row also sets settingable_id and would
  # otherwise fail Rails' "must exist" check.
  belongs_to :season, foreign_key: :settingable_id, inverse_of: :setting, optional: true

  # nil for a Game-owned row (no `season`) — read `settingable` directly for that case.
  has_one :game, through: :season

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
  # Looks up Season first — a direct join on settingable_id would need a
  # bigint cast, which fails on Game-owned rows (non-numeric id).
  def self.nearest_prior(season)
    season_setting_ids = where(settingable_type: 'Season').select(Arel.sql('settingable_id::bigint'))
    candidate_season = Season.where(id: season_setting_ids)
                             .where(game_id: season.game_id, end_date: ...season.start_date)
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
