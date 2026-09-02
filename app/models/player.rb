class Player < ApplicationRecord

  attr_accessor :cost

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

  def latest_score(season: nil)
    scores = external_scores
    scores = scores.joins(:player_season).where(player_seasons: { season_id: season.id }) if season.present?
    scores.order('created_at desc').first&.score
  end

  def record_score!(score:, season:)
    return if Integer(score) == current_score

    player_season = player_seasons.find_or_create_by!(season:)
    player_season.external_scores.create!(score:)
  end

  def latest_score_before(date:)
    external_scores.order('created_at desc').where(created_at: ..date).first&.score || 0
  end

  def decorated_cost
    format('%0.02f', cost)
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
