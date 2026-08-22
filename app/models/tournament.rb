class Tournament < ApplicationRecord

  scope :upcoming, -> { where('starting_date > ?', DateTime.current) }
  belongs_to :game
  validates :name, presence: true
  validates :external_id, presence: true
  validates :starting_date, presence: true
  validates :field_size, numericality: { greater_than: 0 }, allow_nil: true
  has_many :salary_drafts, dependent: :destroy
  has_many :results, dependent: :destroy
  has_many :external_requests, as: :requestable, dependent: :nullify

  enum format: { standard: 0, expanded: 1 }

  include ExternalResource

end
