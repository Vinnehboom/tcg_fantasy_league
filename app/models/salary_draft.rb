class SalaryDraft < ApplicationRecord

  belongs_to :tournament
  validates :price_cap, presence: true
  validates :roster_size, presence: true

end
