class Tournament < ApplicationRecord

  belongs_to :game
  validates :name, presence: true
  validates :external_id, presence: true
  validates :starting_date, presence: true

  enum format: { standard: 0, expanded: 1 }

end
