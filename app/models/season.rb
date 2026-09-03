class Season < ApplicationRecord

  # A default season stands in for a game with no seasons at all — either a
  # genuinely seasonless game (Riftbound) or a game not yet configured with
  # real ones — so scoring always has a covering Season to read config from.
  # 1970 is not meaningful on its own; it's just a start date early enough
  # that this season covers every real date the app will ever see.
  DEFAULT_SEASON_LABEL = 'default'.freeze
  DEFAULT_SEASON_START_DATE = Date.new(1970, 1, 1)

  belongs_to :game
  has_one :setting, as: :settingable, dependent: :destroy
  has_many :player_seasons, dependent: :destroy
  has_many :players, through: :player_seasons

  validates :label, presence: true
  validates :start_date, presence: true
  validate :end_date_after_start_date
  validate :no_overlapping_range_for_game

  scope :covering, lambda { |date|
    where(start_date: ..date).where(end_date: date..).or(where(start_date: ..date, end_date: nil))
  }

  # Idempotent: only creates a row when the game has no seasons of its own
  # yet (default or otherwise). Called from db/seeds.rb only — never from
  # the scoring path itself, which must raise on a genuinely missing season
  # rather than silently create one mid-request.
  def self.default_for(game:)
    return if game.seasons.exists?

    create!(game:, label: DEFAULT_SEASON_LABEL, start_date: DEFAULT_SEASON_START_DATE, end_date: nil)
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank? || end_date >= start_date

    errors.add(:end_date, :before_start_date)
  end

  def no_overlapping_range_for_game
    return if game_id.blank? || start_date.blank?

    candidates = Season.where(game_id:).where.not(id:)
    candidates = candidates.where(start_date: ..end_date) if end_date.present?
    overlapping = candidates.where(end_date: start_date..).or(candidates.where(end_date: nil))
    errors.add(:start_date, :overlapping_season) if overlapping.exists?
  end

end
