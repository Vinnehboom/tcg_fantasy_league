class Participation < ApplicationRecord

  belongs_to :draft, class_name: 'SalaryDraft'
  belongs_to :user
  validates :user, uniqueness: { scope: :draft }
  has_one :tournament, through: :draft
  has_many :rosters, dependent: :destroy
  validates :status, presence: true

  enum status: { created: 0, submitted: 1, completed: 2 }

end
