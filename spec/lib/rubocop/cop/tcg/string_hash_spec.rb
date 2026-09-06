require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../../lib/rubocop/cop/tcg/string_hash'

describe RuboCop::Cop::Tcg::StringHash, :config do
  include RuboCop::RSpec::ExpectOffense

  it 'rejects hash as a seed' do
    expect_offense(<<~RUBY)
      Faker::Config.random = Random.new(player.name.hash)
                                                    ^^^^ `#hash` is randomized per process. Use `Zlib.crc32` or a `Digest` value for a seed, a cache key, or anything else that must repeat across runs.
    RUBY
  end

  it 'rejects hash reached with a safe navigation call' do
    expect_offense(<<~RUBY)
      key = player&.hash
                    ^^^^ `#hash` is randomized per process. Use `Zlib.crc32` or a `Digest` value for a seed, a cache key, or anything else that must repeat across runs.
    RUBY
  end

  it 'accepts hash inside a hash method definition' do
    expect_no_offenses(<<~RUBY)
      def hash
        [name, season].hash
      end
    RUBY
  end

  it 'accepts a reproducible checksum' do
    expect_no_offenses(<<~RUBY)
      Faker::Config.random = Random.new(Zlib.crc32(player.name))
    RUBY
  end

  it 'accepts a call that takes arguments' do
    expect_no_offenses(<<~RUBY)
      cache.hash(key)
    RUBY
  end
end
