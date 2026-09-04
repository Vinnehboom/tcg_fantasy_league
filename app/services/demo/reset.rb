module Demo

  # Truncates every application table (H-9, Decisions D10) — a sharper tool
  # than anything else in this repo, kept only because the historical slice
  # freezes its dates and needs an occasional way back to a clean, current
  # dataset. Nothing drops, no migration re-runs, and the schema stays
  # untouched: connection.truncate_tables already excludes schema_migrations
  # and ar_internal_metadata on its own. Sequences are not reset, so ids
  # keep climbing across a reseed — callers must never hardcode one.
  #
  # Bounded four ways: an environment allow-list (not a deny-list, so a new
  # environment is refused by default); an explicit confirmation; this
  # class's own production guard, independent of Demo::Seeder's and the
  # synthetic adapter's; and nothing but the demo:reseed rake task calls it.
  class Reset

    ALLOWED_ENVIRONMENTS = %w[development test].freeze

    def self.call(confirm:)
      new(confirm:).call
    end

    def initialize(confirm:)
      @confirm = confirm
    end

    def call
      raise_outside_allowed_environment!
      raise_without_confirmation!
      connection.truncate_tables(*connection.tables)
    end

    private

    attr_reader :confirm

    def raise_outside_allowed_environment!
      return if ALLOWED_ENVIRONMENTS.include?(Rails.env)

      raise ExternalData::Exception.new(
        'Demo reset not permitted here',
        "#{self.class.name} only runs in #{ALLOWED_ENVIRONMENTS.join(' or ')}, not '#{Rails.env}'"
      )
    end

    def raise_without_confirmation!
      return if confirm

      raise ExternalData::Exception.new(
        'Demo reset needs confirmation',
        "Refused: this would truncate #{connection.tables.length} tables in database " \
        "'#{connection.pool.db_config.database}', including users. Pass confirm: true to proceed."
      )
    end

    def connection
      ActiveRecord::Base.connection
    end

  end

end
