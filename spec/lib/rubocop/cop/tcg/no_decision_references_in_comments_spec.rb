require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../../lib/rubocop/cop/tcg/no_decision_references_in_comments'

describe RuboCop::Cop::Tcg::NoDecisionReferencesInComments, :config do
  include RuboCop::RSpec::ExpectOffense

  it 'rejects a ticket id' do
    expect_offense(<<~RUBY)
      # Placement has no numericality validation yet (C-12).
                                                      ^^^^ Comment refers to a decision or to where one is recorded (C-12). State the constraint itself, not its history.
      value = 1
    RUBY
  end

  it 'rejects a pull request or issue number' do
    expect_offense(<<~RUBY)
      # Reverted on #94 because the adapter changed.
                    ^^^ Comment refers to a decision or to where one is recorded (#94). State the constraint itself, not its history.
      value = 1
    RUBY
  end

  it 'rejects a reference to the decisions database' do
    expect_offense(<<~RUBY)
      # See the Decisions row for why composition won here.
                ^^^^^^^^^ Comment refers to a decision or to where one is recorded (Decisions). State the constraint itself, not its history.
      value = 1
    RUBY
  end

  it 'rejects a reference to a review round' do
    expect_offense(<<~RUBY)
      # Added in review round 2.
                 ^^^^^^^^^^^^ Comment refers to a decision or to where one is recorded (review round). State the constraint itself, not its history.
      value = 1
    RUBY
  end

  it 'accepts a comment that states a constraint without its history' do
    expect_no_offenses(<<~RUBY)
      # A negative placement scores as zero, because the source feed sends -1 for a no-show.
      value = 1
    RUBY
  end

  it 'accepts a hyphenated technical name that looks like a ticket id' do
    expect_no_offenses(<<~RUBY)
      # The feed sends UTF-8 text and ISO-8601 timestamps.
      value = 1
    RUBY
  end

  it 'accepts a rubocop directive' do
    expect_no_offenses(<<~RUBY)
      value = 1 # rubocop:disable Layout/LineLength
    RUBY
  end

  context 'when the patterns are configured' do
    let(:cop_config) { { 'ForbiddenPatterns' => ['\\bwontfix\\b'] } }

    it 'uses the configured patterns instead of the defaults' do
      expect_no_offenses(<<~RUBY)
        # Deferred to C-12.
        value = 1
      RUBY
    end

    it 'rejects a match on a configured pattern' do
      expect_offense(<<~RUBY)
        # Marked wontfix upstream.
                 ^^^^^^^ Comment refers to a decision or to where one is recorded (wontfix). State the constraint itself, not its history.
        value = 1
      RUBY
    end
  end
end
