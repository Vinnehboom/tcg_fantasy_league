class PlayerSeason < ApplicationRecord

  attr_writer :latest_score

  belongs_to :player, inverse_of: :player_seasons
  belongs_to :season
  has_many :external_scores, dependent: :destroy
  has_many :player_season_modifiers, dependent: :destroy
  has_many :score_modifiers, through: :player_season_modifiers
  validates :player_id, uniqueness: { scope: :season_id }

  def latest_score
    return @latest_score if defined?(@latest_score)

    @latest_score = external_scores.order(created_at: :desc, id: :desc).first&.score
  end

  def record_score!(score:)
    return if Integer(score) == latest_score

    external_scores.create!(score:)
    self.latest_score = Integer(score)
  end

end
