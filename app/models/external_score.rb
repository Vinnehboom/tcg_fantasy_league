class ExternalScore < ApplicationRecord

  belongs_to :player
  validates :score, presence: true, uniqueness: { scope: :player_id }

end
