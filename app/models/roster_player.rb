class RosterPlayer < ApplicationRecord

  belongs_to :player
  belongs_to :roster
  has_one :participation, through: :roster
  has_one :draft, through: :participation

  def player_cost
    draft.cost_for(player:)
  end

  def decorated_player_cost
    format('%0.02f', player_cost)
  end

end
