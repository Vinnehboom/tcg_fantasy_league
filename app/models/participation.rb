class Participation < ApplicationRecord

  belongs_to :draft, class_name: 'SalaryDraft'
  belongs_to :user
  validates :user, uniqueness: { scope: :draft }

end
