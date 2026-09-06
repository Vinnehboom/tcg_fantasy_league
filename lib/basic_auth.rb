require 'active_support/security_utils'

class BasicAuth

  USERNAME_VARIABLE = 'BASIC_AUTH_USERNAME'.freeze
  PASSWORD_VARIABLE = 'BASIC_AUTH_PASSWORD'.freeze

  def self.from_env(env = ENV)
    new(username: env[USERNAME_VARIABLE], password: env[PASSWORD_VARIABLE])
  end

  def initialize(username:, password:)
    @expected_username = username
    @expected_password = password
  end

  def authorized?(username:, password:)
    return false unless configured?

    # `&` and not `&&`: both comparisons always run, so a wrong username takes
    # the same time to reject as a wrong password.
    matches?(given: username, expected: expected_username) &
      matches?(given: password, expected: expected_password)
  end

  private

  attr_reader :expected_username, :expected_password

  def configured?
    expected_username.present? && expected_password.present?
  end

  def matches?(given:, expected:)
    ActiveSupport::SecurityUtils.secure_compare(given.to_s, expected)
  end

end
