class Player < ApplicationRecord

  attr_accessor :cost

  validates :name, presence: true
  validates :external_id, presence: true
  belongs_to :game
  has_many :external_scores, dependent: :destroy
  accepts_nested_attributes_for :external_scores

  def current_score
    external_scores.order('created_at desc').first&.score
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

end
