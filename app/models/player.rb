class Player < ApplicationRecord

  validates :name, presence: true
  validates :external_id, presence: true
  validates :external_points, presence: true
  belongs_to :game

  include ExternalResource

end
