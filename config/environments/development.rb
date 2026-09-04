require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Eager load code on boot: an autoloaded constant nothing has referenced
  # yet - such as one of ScoreModifier's STI subclasses - is missing from
  # ScoreModifier.subclasses until something else loads it first.
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  # No live HTTP call from local development (H-9): every ExternalData
  # import uses the synthetic adapter instead of the real one. The real
  # adapter (the block ImportJob#adapter passes in) is therefore never
  # invoked here, so it is never constructed either.
  #
  # The real behavior lives in ExternalData::Synthetic::AdapterBuilder, a
  # plain, directly testable class (app/services/external_data/synthetic) —
  # not written out here, so this assignment stays the only untested line
  # (development itself cannot be booted in this sandbox: no
  # development.key). The reference has to be inside a lambda, evaluated
  # only when actually called: this file loads before the autoloader is set
  # up, so a bare top-level ExternalData::Synthetic::AdapterBuilder.new here
  # would raise NameError on every boot, in every environment.
  config.x.external_data.adapter_builder = lambda do |game:, &live_adapter|
    ExternalData::Synthetic::AdapterBuilder.new.call(game:, &live_adapter)
  end

  # Same idea for the admin "verify tournament id" flow, via
  # ExternalData::Synthetic::VerifierBuilder.
  config.x.external_data.verifier_builder = lambda do |game:, &registered_verifier|
    ExternalData::Synthetic::VerifierBuilder.new.call(game:, &registered_verifier)
  end
end
