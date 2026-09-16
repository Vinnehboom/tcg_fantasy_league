class Player < ApplicationRecord

  attr_accessor :cost

  scope :not_suppressed, -> { where(suppressed_at: nil) }
  scope :suppressed, -> { where.not(suppressed_at: nil) }

  validates :name, presence: true
  validates :external_id, presence: true
  belongs_to :game
  has_many :results, dependent: :destroy
  has_many :external_requests, as: :requestable, dependent: :nullify
  has_many :player_seasons, dependent: :destroy
  has_many :seasons, through: :player_seasons
  has_many :external_scores, through: :player_seasons

  def current_score
    external_scores.order('created_at desc').first&.score
  end

  def record_score!(score:, season:)
    player_seasons.find_or_create_by!(season:).record_score!(score:)
  end

  def latest_score_before(date:)
    external_scores.order('created_at desc').where(created_at: ..date).first&.score || 0
  end

  def decorated_cost
    format('%0.02f', cost)
  end

  def suppressed?
    suppressed_at.present?
  end

  def name
    return I18n.t('players.suppressed_display_name') if suppressed?

    super
  end

  def raw_name
    self[:name]
  end

  def score_difference(date:, other_date:)
    score = latest_score_before(date:)
    other_score = latest_score_before(date: other_date)
    score - other_score
  end

  include ExternalResource

  def external_url
    season = game.current_season
    return super unless season

    "#{super}?season=#{CGI.escape(season.label)}"
  end

end
