class SalaryDraft < ApplicationRecord

  belongs_to :tournament
  has_many :participations, foreign_key: :draft_id, dependent: :destroy, inverse_of: :draft
  validates :price_cap, presence: true
  validates :roster_size, presence: true

end
