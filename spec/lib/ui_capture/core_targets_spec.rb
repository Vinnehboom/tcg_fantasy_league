require 'rails_helper'

RSpec.describe UiCapture::CoreTargets do
  # A route built this way has no `required_parts`, so the filtering
  # examples below never touch the database -- they exercise the filtering
  # rules in isolation, against this app's own real controllers.
  def fake_route_class
    @fake_route_class ||= Struct.new(:verb, :controller, :action, :name, keyword_init: true) do
      def defaults
        { controller:, action: }
      end

      def required_parts
        []
      end

      def format(_values)
        "/#{controller}/#{action}"
      end
    end
  end

  def fake_route(**attrs)
    fake_route_class.new(**attrs)
  end

  def targets_for(route)
    described_class.call(routes: [route])
  end

  describe '.call — filtering' do
    it 'keeps a GET route whose controller implements the action' do
      route = fake_route(verb: 'GET', controller: 'admin/score_modifiers', action: 'show',
                         name: 'admin_score_modifier')

      expect(targets_for(route).pluck(:name)).to eq(['admin-score-modifier'])
    end

    it 'marks a kept target kind as still' do
      route = fake_route(verb: 'GET', controller: 'admin/games', action: 'index', name: 'admin_games')

      expect(targets_for(route).first[:kind]).to eq('still')
    end

    it 'drops a non-GET route sharing a path-helper name with a kept GET route' do
      # Admin::ScoreModifiersController implements both; "admin_score_modifier"
      # names the GET show route and the DELETE destroy route alike.
      route = fake_route(verb: 'DELETE', controller: 'admin/score_modifiers', action: 'destroy',
                         name: 'admin_score_modifier')

      expect(targets_for(route)).to be_empty
    end

    it 'drops a GET route whose controller does not implement the action' do
      # PlayersController has `index` only; config/routes.rb still declares
      # the full `resources :players`, so this route exists and 404s.
      route = fake_route(verb: 'GET', controller: 'players', action: 'show', name: 'game_player')

      expect(targets_for(route)).to be_empty
    end

    it 'drops the JSON admin API namespace' do
      route = fake_route(verb: 'GET', controller: 'admin/api/tournaments', action: 'index', name: 'x')

      expect(targets_for(route)).to be_empty
    end

    it 'drops a framework-mounted route' do
      route = fake_route(verb: 'GET', controller: 'active_storage/blobs', action: 'show', name: 'x')

      expect(targets_for(route)).to be_empty
    end

    it 'drops a Devise route that is not the sign-in or sign-up page' do
      route = fake_route(verb: 'GET', controller: 'devise/passwords', action: 'new', name: 'new_user_password')

      expect(targets_for(route)).to be_empty
    end

    it 'keeps the Devise sign-in page' do
      route = fake_route(verb: 'GET', controller: 'devise/sessions', action: 'new', name: 'new_user_session')

      expect(targets_for(route).pluck(:name)).to eq(['new-user-session'])
    end

    it 'marks the Devise sign-in page signed_out' do
      route = fake_route(verb: 'GET', controller: 'devise/sessions', action: 'new', name: 'new_user_session')

      expect(targets_for(route).first[:signed_out]).to be(true)
    end

    it 'marks the landing page signed_out' do
      route = fake_route(verb: 'GET', controller: 'pages', action: 'landing', name: 'root')

      expect(targets_for(route).first[:signed_out]).to be(true)
    end

    it 'does not mark an ordinary page signed_out' do
      route = fake_route(verb: 'GET', controller: 'admin/games', action: 'index', name: 'admin_games')

      expect(targets_for(route).first[:signed_out]).to be_nil
    end
  end

  describe '.call — against the real route table' do
    it 'fills a dynamic segment from seeded demo data' do
      game = create(:game, :ptcg)

      target = described_class.call.find { |t| t[:name] == 'admin-game' }

      expect(target[:path]).to eq("/admin/games/#{game.id}")
    end

    it 'does not pair a child record with a :game segment it does not belong to' do
      create(:game) # sorts first; Game.first resolves the :game segment to this one
      other_game = create(:game)
      create(:salary_draft, tournament: create(:tournament, game: other_game))

      names = described_class.call.pluck(:name)

      expect(names).not_to include('game-salary-draft')
    end
  end

  describe '#skipped' do
    it 'skips and reports a segment it cannot fill' do
      create(:game, :ptcg) # no ScoreModifier seeded

      resolver = described_class.new
      targets = resolver.call

      aggregate_failures do
        expect(targets.pluck(:name)).not_to include('admin-score-modifier')
        expect(resolver.skipped).to include(a_string_matching(/admin-score-modifier/))
      end
    end
  end
end
