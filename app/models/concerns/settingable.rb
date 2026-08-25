# A model that stores one JSONB settings payload for another record (its
# +settingable+). Includers get the polymorphic association, presence and
# uniqueness validation on the payload, and a `.for(settingable:)` lookup
# that returns the settingable's own row, or nil.
#
# `.for` can also carry a row forward from a "prior" settingable when the
# exact settingable has none of its own, but what "prior" means is specific
# to each settingable's own domain (for a Season, it's the nearest earlier
# season of the same game) — so includers define that by overriding the
# +nearest_prior+ hook. Left undefined, there is no carry-forward: `.for`
# simply returns nil.
module Settingable

  extend ActiveSupport::Concern

  included do
    belongs_to :settingable, polymorphic: true

    validates :settings, presence: true
    validates :settingable_id, uniqueness: { scope: :settingable_type }
  end

  class_methods do
    def for(settingable:)
      find_by(settingable:) || nearest_prior(settingable)
    end

    private

    def nearest_prior(_settingable)
      nil
    end
  end

end
