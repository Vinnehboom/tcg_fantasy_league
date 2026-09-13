class Result < ApplicationRecord

  belongs_to :player, inverse_of: :results
  belongs_to :tournament
  validates :placement, presence: true
  validates :player_id, uniqueness: { scope: :tournament_id }

end
