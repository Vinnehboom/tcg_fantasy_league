class Tournament < ApplicationRecord

  scope :upcoming, -> { where('starting_date > ?', DateTime.current) }
  belongs_to :game
  validates :name, presence: true
  validates :external_id, presence: true
  validates :starting_date, presence: true
  has_many :salary_drafts, dependent: :destroy

  enum format: { standard: 0, expanded: 1 }

  include ExternalResource

end
