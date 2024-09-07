class Participation < ApplicationRecord

  belongs_to :draft, class_name: 'SalaryDraft'
  belongs_to :user
  validates :user, uniqueness: { scope: :draft }
  has_one :tournament, through: :draft
  has_many :rosters, dependent: :destroy
  validates :status, presence: true

  validate :rosters_complete, on: :update

  enum status: { created: 0, submitted: 1, completed: 2 }

  private

  def rosters_complete
    return true if rosters.present? && rosters.all? { |roster| roster.roster_players.present? }

    errors.add(:rosters, :empty)
  end

end
