class SalaryDraft < ApplicationRecord

  scope :upcoming, -> { includes(:tournament).where(tournament: { starting_date: Date.current.. }) }
  belongs_to :tournament
  has_one :game, through: :tournament
  has_many :participations, foreign_key: :draft_id, dependent: :destroy, inverse_of: :draft
  validates :price_cap, presence: true
  validates :roster_size, presence: true

  def cost_for(player:)
    Players::CostCalculator.new(pricing_rules: [Players::ScalingPriceRule.new]).calculate_cost(player:, tournament:)
  end

  def score_for(cost:)
    Players::ScoreCalculator.new(pricing_rules: [Players::ScalingPriceRule.new]).calculate_score(cost:)
  end

end
