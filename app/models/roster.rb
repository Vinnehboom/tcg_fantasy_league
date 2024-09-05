class Roster < ApplicationRecord

  belongs_to :participation
  has_one :user, through: :participation
  has_one :draft, through: :participation
  has_one :tournament, through: :participation
  has_many :roster_players, dependent: :destroy
  has_many :players, through: :roster_players

  accepts_nested_attributes_for :roster_players, allow_destroy: true

  validate :roster_size
  validate :roster_cost

  def total_cost
    roster_players.sum { |roster_player| roster_player.player_cost.to_f }.round(2)
  end

  private

  def roster_size
    return true unless draft && roster_players.length > draft.roster_size

    errors.add(:players, :roster_too_big)
  end

  def roster_cost
    return true unless draft && total_cost > draft.price_cap

    errors.add(:players, :total_cost_exceeded)
  end

end
