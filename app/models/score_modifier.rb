class ScoreModifier < ApplicationRecord

  include Discard::Model

  has_many :player_season_modifiers, dependent: :destroy
  has_many :player_seasons, through: :player_season_modifiers

  # The closed vocabulary an admin can name a modifier from. A modifier's
  # name is shown next to a real player's name, so it can't be free text
  # (defamation and UK GDPR Article 5(1)(d) accuracy exposure, per legal
  # review 2026-09-02 on C-27).
  enum :name, {
    'hot streak' => 'hot streak',
    'winner' => 'winner',
    'world champion' => 'world champion',
    'legend' => 'legend',
    'upcoming' => 'upcoming'
  }, validate: true

  validates :value, presence: true, numericality: true
  validates :type, inclusion: { in: ->(_modifier) { ScoreModifier.subclasses.map(&:name) } }

  # No default_scope: Discard::Model already gives every caller the two
  # scopes it needs - .kept for "an admin picking from the live list" and
  # .discarded (or no scope at all, via a plain association/find) for
  # "still needs to resolve a modifier that's since been discarded." An
  # implicit default made that choice invisible at the call site.

  # Pundit derives the policy from the record's own class, and the subtypes
  # have no policy of their own.
  def self.policy_class
    ScoreModifierPolicy
  end

  def apply(score)
    raise NotImplementedError, "#{self.class} must implement #apply"
  end

end
