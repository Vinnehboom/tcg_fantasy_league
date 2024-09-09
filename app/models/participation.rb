class Participation < ApplicationRecord

  belongs_to :draft, class_name: 'SalaryDraft'
  belongs_to :user
  validates :user, uniqueness: { scope: :draft }
  has_one :tournament, through: :draft
  has_one :game, through: :tournament
  has_many :rosters, dependent: :destroy, autosave: true
  has_many :players, through: :rosters
  has_many :roster_players, through: :rosters, autosave: true
  validates :status, presence: true

  validate :rosters_complete, on: :update

  enum status: { created: 0, submitted: 1, completed: 2 }

  def score
    roster_players.sum(:score)
  end

  private

  def rosters_complete
    return true if rosters.present? && rosters.all? { |roster| roster.roster_players.present? }

    errors.add(:rosters, :empty)
  end

end
