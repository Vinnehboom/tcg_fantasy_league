require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TcgFantasyDraft
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Composition root for ExternalData::ImportJob#adapter (H-9). A lambda,
    # not a class name — no constantize, no id-keyed registry. This default
    # always uses the real collaborator; an environment file can swap in a
    # different one (see config/environments/development.rb). The block a
    # caller passes in (the real adapter) is evaluated lazily, so a builder
    # that never calls it never constructs the real thing.
    config.x.external_data.adapter_builder = ->(**, &live_adapter) { live_adapter.call }

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    #
    def self.credentials
      @credentials ||= Rails.application.credentials
    end
  end
end
