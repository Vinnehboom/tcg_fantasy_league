class Game < ApplicationRecord

  validates :name, presence: true
  validates :base_uri, presence: true

  has_many :players

end
