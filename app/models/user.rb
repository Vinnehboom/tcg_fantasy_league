class User < ApplicationRecord

  rolify

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, presence: true
  validates :username, presence: true, uniqueness: true
  has_many :participations, dependent: :destroy
  has_many :rosters, through: :participations

  def admin?
    has_role?(:admin)
  end

  def highscore
    participations.sum(&:score)
  end

end
