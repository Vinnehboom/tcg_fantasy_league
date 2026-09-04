require 'rails_helper'

RSpec.describe 'config/environments/development.rb' do
  it 'eager loads code on boot, so ScoreModifier.subclasses is populated on the first request' do
    # Resolve the real path, and read the file, before stubbing
    # Rails.application below - Rails.root itself reads through it.
    environment_file = Rails.root.join('config/environments/development.rb').read

    # A permissive recorder: development.rb sets many config.* values we
    # don't care about here (cache_classes, active_support.deprecation,
    # ...), and some of those are themselves nested objects
    # (config.action_mailer.*). Records just eager_load and no-ops/chains
    # through everything else.
    recorder = Struct.new(:eager_load) do
      def method_missing(*)
        self
      end

      def respond_to_missing?(*)
        true
      end
    end.new

    # Rails::Railtie#configure runs the block with `instance_eval`, so a
    # bare `config` inside it resolves as a method on the application
    # itself (not a block param) - the fake needs the same shape.
    fake_application = Object.new
    fake_application.define_singleton_method(:config) { recorder }
    fake_application.define_singleton_method(:configure) { |&block| instance_eval(&block) }
    allow(Rails).to receive(:application).and_return(fake_application)

    eval(environment_file, binding, 'config/environments/development.rb') # rubocop:disable Security/Eval -- evaluating our own repo's config file, not external input

    expect(recorder.eager_load).to be true
  end
end
