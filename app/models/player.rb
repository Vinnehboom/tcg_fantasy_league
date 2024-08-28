class Player < ApplicationRecord

  validates :name, presence: true
  validates :external_id, presence: true
  belongs_to :game
  has_many :external_scores, dependent: :destroy
  accepts_nested_attributes_for :external_scores

  def current_score
    external_scores.order('created_at desc').first&.score
  end

  include ExternalResource

end
