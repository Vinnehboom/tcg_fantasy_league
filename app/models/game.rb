class Game < ApplicationRecord

  validates :name, presence: true
  validates :base_uri, presence: true

  has_many :players, dependent: :nullify
  has_many :tournaments, dependent: :nullify
  has_many :salary_drafts, through: :tournaments
  has_many :external_requests, -> { with_discarded }, dependent: :restrict_with_error, inverse_of: :game

  def upcoming_drafts
    salary_drafts.upcoming
  end

end
