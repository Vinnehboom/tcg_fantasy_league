module Demo

  # Truncates every application table (H-9, Decisions D10) — a sharper tool
  # than anything else in this repo, kept only because the historical slice
  # freezes its dates and needs an occasional way back to a clean, current
  # dataset. Nothing drops, no migration re-runs, and the schema stays
  # untouched: connection.truncate_tables already excludes schema_migrations
  # and ar_internal_metadata on its own. Sequences are not reset, so ids
  # keep climbing across a reseed — callers must never hardcode one.
  #
  # Bounded five ways: an environment allow-list (not a deny-list, so a new
  # environment is refused by default); a check that the connected database
  # is actually the expected one for that environment, in case DATABASE_URL
  # points RAILS_ENV=development at some other database; an explicit
  # confirmation; this class's own production guard, independent of
  # Demo::Seeder's and the synthetic adapter's; and nothing but the
  # demo:reseed rake task calls it.
  class Reset < ApplicationService

    ALLOWED_ENVIRONMENTS = %w[development test].freeze

    def initialize(confirm:)
      super()
      @confirm = confirm
    end

    def call
      raise_outside_allowed_environment!
      raise_outside_expected_database!
      raise_without_confirmation!
      connection.truncate_tables(*connection.tables)
    end

    private

    attr_reader :confirm

    def raise_outside_allowed_environment!
      return if ALLOWED_ENVIRONMENTS.include?(Rails.env)

      raise "#{self.class.name} only runs in #{ALLOWED_ENVIRONMENTS.join(' or ')}, not '#{Rails.env}'"
    end

    # Rails.env alone only says what config/environments file loaded — a
    # DATABASE_URL override still wins over config/database.yml underneath
    # it, so a RAILS_ENV=development process can be connected to any
    # database at all. This checks the actual connection, independent of
    # what Rails.env claims.
    def raise_outside_expected_database!
      return if expected_database_names.include?(connected_database_name)

      raise "#{self.class.name} refuses: connected to database '#{connected_database_name}', which is not " \
            "the expected database for Rails.env '#{Rails.env}' — check DATABASE_URL"
    end

    def raise_without_confirmation!
      return if confirm

      raise "#{self.class.name} refused without confirmation: this would truncate #{connection.tables.length} " \
            "tables in database '#{connected_database_name}', including users. Pass confirm: true to proceed."
    end

    def connected_database_name
      connection.pool.db_config.database
    end

    def expected_database_names
      base_name = Rails.application.credentials.db.name
      [base_name, "#{base_name}#{ENV.fetch('TEST_ENV_NUMBER', nil)}"]
    end

    def connection
      ActiveRecord::Base.connection
    end

  end

end
