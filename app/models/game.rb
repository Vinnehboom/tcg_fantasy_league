class Game < ApplicationRecord

  validates :name, presence: true
  validates :base_uri, presence: true

  has_many :players, dependent: :nullify
  has_many :tournaments, dependent: :nullify
  has_many :salary_drafts, through: :tournaments
  has_many :external_requests, dependent: :restrict_with_error
  has_many :seasons, dependent: :destroy

  def upcoming_drafts
    salary_drafts.upcoming
  end

  def current_season(on: Date.current)
    seasons.covering(on).sole
  rescue ActiveRecord::RecordNotFound
    nil
  end

end
