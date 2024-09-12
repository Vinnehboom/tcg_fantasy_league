class Game < ApplicationRecord

  validates :name, presence: true
  validates :base_uri, presence: true

  has_many :players, dependent: :nullify
  has_many :tournaments, dependent: :nullify
  has_many :salary_drafts, through: :tournaments

  def upcoming_drafts
    salary_drafts.upcoming
  end

end
