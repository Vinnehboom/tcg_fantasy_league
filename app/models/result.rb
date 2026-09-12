class Result < ApplicationRecord

  belongs_to :player, -> { unscope(where: :suppressed_at) }, inverse_of: :results
  belongs_to :tournament
  validates :placement, presence: true
  validates :player_id, uniqueness: { scope: :tournament_id }

end
