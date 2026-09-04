module Demo

  # Truncates every application table. Sequences are not reset, so ids keep
  # climbing across a reseed — callers must never hardcode one.
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

    # DATABASE_URL can point RAILS_ENV=development at any database, so this
    # checks the actual connection instead of trusting Rails.env alone.
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
