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

  it "builds a mailer URL from Render's own hostname" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch)
      .with('RENDER_EXTERNAL_HOSTNAME', anything)
      .and_return('tcg-fantasy-league.onrender.com')

    calls = evaluate_production_config.action_mailer.calls

    expect(calls).to include([:default_url_options=, [{ host: 'tcg-fantasy-league.onrender.com' }]])
  end

  def registered_basic_auth
    recorded_middleware(evaluate_production_config)
      .find { |arguments, _block| arguments.first == Rack::Auth::Basic }
      .then { |arguments, block| [*arguments, block] }
  end

  def recorded_middleware(config)
    config.middleware.calls
  end

  # Production cannot be booted here (no production.key), so the config file is
  # evaluated against recorders - the same approach development_spec.rb takes.
  # Read the file before stubbing Rails.application: Rails.root reads through it.
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
  # of them nested, so everything but the middleware stack and action_mailer
  # has to chain through.
  def config_recorder
    middleware = Struct.new(:calls) do
      def use(*arguments, &block)
        calls << [arguments, block]
      end
    end.new([])

    Struct.new(:middleware, :action_mailer) do
      def method_missing(*)
        self
      end

      def respond_to_missing?(*)
        true
      end
    end.new(middleware, call_recorder)
  end

  def call_recorder
    Struct.new(:calls) do
      def method_missing(name, *arguments)
        calls << [name, arguments]
      end

      def respond_to_missing?(*)
        true
      end
    end.new([])
  end
end
