require 'rails_helper'

RSpec.describe 'config/environments/production.rb' do
  it 'puts every production request behind HTTP basic auth' do
    middleware_class, realm, = registered_basic_auth

    expect(middleware_class).to eq(Rack::Auth::Basic)
    expect(realm).to be_present
  end

  it 'checks the credentials the browser sends against the ones the deploy configured' do
    auth = instance_double(BasicAuth, authorized?: true)
    allow(BasicAuth).to receive(:from_env).and_return(auth)
    credential_check = registered_basic_auth.last

    credential_check.call('vinnie', 's3cret')

    expect(auth).to have_received(:authorized?).with(username: 'vinnie', password: 's3cret')
  end

  # Returns the recorded `config.middleware.use Rack::Auth::Basic, realm, &block`
  # call as [middleware_class, realm, block]. Production cannot be booted here
  # (no production.key), so the config file is evaluated against recorders
  # instead - the same approach development_spec.rb takes.
  def registered_basic_auth
    recorded_middleware(evaluate_production_config)
      .find { |arguments, _block| arguments.first == Rack::Auth::Basic }
      .then { |arguments, block| [*arguments, block] }
  end

  def recorded_middleware(config)
    config.middleware.calls
  end

  # Resolve the path, and read the file, before stubbing Rails.application
  # below - Rails.root itself reads through it.
  def evaluate_production_config
    environment_file = Rails.root.join('config/environments/production.rb').read
    config = config_recorder

    fake_application = Object.new
    fake_application.define_singleton_method(:config) { config }
    fake_application.define_singleton_method(:configure) { |&block| instance_eval(&block) }
    allow(Rails).to receive(:application).and_return(fake_application)

    eval(environment_file, binding, 'config/environments/production.rb') # rubocop:disable Security/Eval -- evaluating our own repo's config file, not external input

    config
  end

  # production.rb sets many config.* values this spec does not care about, some
  # of them nested (config.action_mailer.*). Records the middleware stack and
  # no-ops/chains through everything else.
  def config_recorder
    middleware = Struct.new(:calls) do
      def use(*arguments, &block)
        calls << [arguments, block]
      end
    end.new([])

    Struct.new(:middleware) do
      def method_missing(*)
        self
      end

      def respond_to_missing?(*)
        true
      end
    end.new(middleware)
  end
end
