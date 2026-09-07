class User < ApplicationRecord

  rolify

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :participations, dependent: :destroy
  has_many :rosters, through: :participations

  validates :email, presence: true
  validates :username, presence: true, uniqueness: true
  validates :country, presence: true,
                      inclusion: { in: ISO3166::Country.codes, allow_blank: true }
  validates :date_of_birth, presence: true,
                            comparison: { less_than_or_equal_to: -> { Date.current }, allow_blank: true }

  def admin?
    has_role?(:admin)
  end

  def age
    return nil if date_of_birth.blank?

    today = Date.current
    years = today.year - date_of_birth.year
    years -= 1 if today < date_of_birth + years.years
    years
  end

  def highscore
    participations.sum(&:score)
  end

  def self.highscorers(game:)
    joins(rosters: [roster_players: :player])
      .group('users.id')
      .where('player.game_id': game.id)
      .where.not('roster_players.score': nil)
      .select('users.*, SUM(roster_players.score) AS total')
      .order('total DESC')
  end

end
