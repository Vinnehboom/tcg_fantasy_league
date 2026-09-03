class Setting < ApplicationRecord

  include Settingable

  # `optional: true` because this reflection matches on settingable_id alone
  # (Rails has no way to also filter it by settingable_type), so a Game-owned
  # row would otherwise fail Rails' automatic "must exist" check against a
  # season it was never meant to have. The real requirement — a Season-owned
  # row must resolve to a real Season — is enforced explicitly below, scoped
  # to that case only.
  belongs_to :season, foreign_key: :settingable_id, inverse_of: :setting, optional: true
  has_one :game, through: :season

  validates :season, presence: true, if: -> { settingable_type == 'Season' }

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
  # Looks up the candidate Season first, rather than joining Setting straight
  # to Season on settingable_id, because settingable_id is a shared string
  # column (it also holds Game ids since the settingable_id-widening
  # migration) — a direct join would need a bigint cast applied to every
  # settings row, including Game-owned ones whose id isn't numeric at all.
  # Filtering to Season-typed rows inside the subquery's own WHERE, before
  # that subquery's SELECT casts settingable_id, keeps the cast scoped to
  # rows it can actually apply to.
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

  # `season=`/`season:` (the public interface kept for Season-owned callers)
  # only sets settingable_id, not settingable_type, so this fills in the
  # other half of the polymorphic pair for that path. A row built through
  # the generic `settingable=` writer (e.g. a Game-owned default row)
  # already has both halves set correctly by Rails' own polymorphic
  # assignment — `||=` leaves that alone instead of clobbering it back to
  # Season.
  def assign_settingable_type
    self.settingable_type ||= 'Season'
  end

end
