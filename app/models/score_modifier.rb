class ScoreModifier < ApplicationRecord

  include Discard::Model

  has_many :player_season_modifiers, dependent: :destroy
  has_many :player_seasons, through: :player_season_modifiers

  enum :name, {
    'hot streak' => 'hot streak',
    'winner' => 'winner',
    'world champion' => 'world champion',
    'legend' => 'legend',
    'upcoming' => 'upcoming'
  }, validate: true

  validates :value, presence: true, numericality: true
  validates :type, inclusion: { in: ->(_modifier) { ScoreModifier.subclasses.map(&:name) } }

  # Pundit derives the policy from the record's own class, and the subtypes
  # have no policy of their own.
  def self.policy_class
    ScoreModifierPolicy
  end

  def apply(score)
    raise NotImplementedError, "#{self.class} must implement #apply"
  end

end
