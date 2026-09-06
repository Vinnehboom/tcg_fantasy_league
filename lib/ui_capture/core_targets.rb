module UiCapture

  class CoreTargets < ApplicationService

    FRAMEWORK_CONTROLLER_PREFIXES = %w[
      rails/health rails/conductor active_storage action_mailbox turbo/native
    ].freeze

    KEPT_DEVISE_ROUTES = { 'devise/sessions' => %w[new], 'devise/registrations' => %w[new] }.freeze

    def initialize(routes: Rails.application.routes.routes)
      super()
      @routes = routes
      @skipped = []
    end

    def call
      page_routes.filter_map { |route| build_target(route) }
    end

    attr_reader :skipped

    private

    attr_reader :routes

    def page_routes
      routes.select { |route| page_route?(route) }
    end

    def page_route?(route)
      route.verb == 'GET' && app_page_controller?(route) && devise_route_kept?(route) && action_implemented?(route)
    end

    def app_page_controller?(route)
      controller = controller_path(route)
      return false if controller.start_with?('admin/api')

      FRAMEWORK_CONTROLLER_PREFIXES.none? { |prefix| controller == prefix || controller.start_with?("#{prefix}/") }
    end

    def devise_route_kept?(route)
      controller = controller_path(route)
      return true unless controller.start_with?('devise/')

      KEPT_DEVISE_ROUTES.fetch(controller, []).include?(route.defaults[:action].to_s)
    end

    # `resources` in config/routes.rb declares the full set of RESTful
    # routes against several controllers that only implement some of them
    # (e.g. PlayersController has `index` only); the route exists and would
    # 404 if visited.
    def action_implemented?(route)
      controller_class(route)&.action_methods&.include?(route.defaults[:action].to_s) || false
    end

    def controller_class(route)
      "#{controller_path(route).camelize}Controller".safe_constantize
    end

    def build_target(route)
      path = fill_path(route)
      return nil unless path

      target = { name: target_name(route), kind: 'still', path: }
      target[:signed_out] = true if signed_out?(route)
      target
    end

    def fill_path(route)
      records = {}
      route.required_parts.each { |part| records[part] = resolved_record(part:, route:, resolved: records) }

      missing = records.select { |_part, record| record.nil? }
      return route.format(records.transform_values(&:to_param)) if missing.empty?

      missing.each_key { |part| skipped << "#{target_name(route)}: no seeded record to fill :#{part}" }
      nil
    end

    def resolved_record(part:, route:, resolved:)
      seeded_record(model_for(part:, route:), game: resolved[:game])
    end

    def model_for(part:, route:)
      name = part == :id ? controller_path(route).split('/').last : part.to_s.delete_suffix('_id')
      name.classify.safe_constantize
    end

    # A model with its own `game` association (Player, Tournament,
    # SalaryDraft...) must be scoped to the :game segment already resolved
    # for this same route, or a still-valid-looking path can pair a record
    # from one game with a different game's :game segment.
    def seeded_record(model, game:)
      return nil unless model

      scoped = game && model.reflect_on_association(:game) ? model.joins(:game).where(games: { id: game.id }) : model
      scoped.first
    end

    def controller_path(route)
      route.defaults[:controller].to_s
    end

    def target_name(route)
      (route.name || "#{controller_path(route)}-#{route.defaults[:action]}").tr('_', '-')
    end

    def signed_out?(route)
      controller = controller_path(route)
      (controller == 'pages' && route.defaults[:action].to_s == 'landing') || controller.start_with?('devise/')
    end

  end

end
