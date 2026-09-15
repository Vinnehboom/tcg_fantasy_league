require 'rails_helper'

RSpec.describe 'A resource trimmed to only the actions its controller implements' do
  def expect_route(method:, path:, to:, **params)
    expect({ method => path }).to route_to(to, **params)
  end

  def expect_no_route(method:, path:)
    expect({ method => path }).not_to be_routable
  end

  describe 'admin/users, scoped to index and show' do
    it 'reaches index' do
      expect_route(method: :get, path: '/admin/users', to: 'admin/users#index')
    end

    it 'reaches show' do
      expect_route(method: :get, path: '/admin/users/1', to: 'admin/users#show', id: '1')
    end

    it 'leaves create unreachable' do
      expect_no_route(method: :post, path: '/admin/users')
    end

    it 'leaves edit unreachable' do
      expect_no_route(method: :get, path: '/admin/users/1/edit')
    end

    it 'leaves update unreachable' do
      expect_no_route(method: :patch, path: '/admin/users/1')
    end

    it 'leaves destroy unreachable' do
      expect_no_route(method: :delete, path: '/admin/users/1')
    end
  end

  describe 'admin/participations, scoped to index and show' do
    it 'reaches index' do
      expect_route(method: :get, path: '/admin/participations', to: 'admin/participations#index')
    end

    it 'reaches show' do
      expect_route(method: :get, path: '/admin/participations/1', to: 'admin/participations#show', id: '1')
    end

    it 'leaves edit unreachable' do
      expect_no_route(method: :get, path: '/admin/participations/1/edit')
    end

    # create/update/destroy are not declared here, but the path still matches
    # something: the public, game-scoped participations resource, treating
    # the literal path segment "admin" as its :game. See the redirect this
    # produces at runtime in spec/requests/admin/participations_spec.rb.
    it 'falls through create to the public participations resource' do
      expect_route(method: :post, path: '/admin/participations', to: 'participations#create', game: 'admin')
    end

    it 'falls through update to the public participations resource' do
      expect_route(method: :patch, path: '/admin/participations/1', to: 'participations#update', game: 'admin', id: '1')
    end

    it 'falls through destroy to the public participations resource' do
      expect_route(method: :delete, path: '/admin/participations/1', to: 'participations#destroy',
                   game: 'admin', id: '1')
    end
  end

  describe 'the game-scoped players resource, scoped to index' do
    it 'reaches index' do
      expect_route(method: :get, path: '/PTCG/players', to: 'players#index', game: 'PTCG')
    end

    it 'leaves new unreachable' do
      expect_no_route(method: :get, path: '/PTCG/players/new')
    end

    it 'leaves create unreachable' do
      expect_no_route(method: :post, path: '/PTCG/players')
    end

    it 'leaves show unreachable' do
      expect_no_route(method: :get, path: '/PTCG/players/1')
    end

    it 'leaves edit unreachable' do
      expect_no_route(method: :get, path: '/PTCG/players/1/edit')
    end

    it 'leaves update unreachable' do
      expect_no_route(method: :patch, path: '/PTCG/players/1')
    end

    it 'leaves destroy unreachable' do
      expect_no_route(method: :delete, path: '/PTCG/players/1')
    end
  end

  describe 'the game-scoped tournaments resource, scoped to index' do
    it 'reaches index' do
      expect_route(method: :get, path: '/PTCG/tournaments', to: 'tournaments#index', game: 'PTCG')
    end

    it 'leaves new unreachable' do
      expect_no_route(method: :get, path: '/PTCG/tournaments/new')
    end

    it 'leaves create unreachable' do
      expect_no_route(method: :post, path: '/PTCG/tournaments')
    end

    it 'leaves show unreachable' do
      expect_no_route(method: :get, path: '/PTCG/tournaments/1')
    end

    it 'leaves edit unreachable' do
      expect_no_route(method: :get, path: '/PTCG/tournaments/1/edit')
    end

    it 'leaves update unreachable' do
      expect_no_route(method: :patch, path: '/PTCG/tournaments/1')
    end

    it 'leaves destroy unreachable' do
      expect_no_route(method: :delete, path: '/PTCG/tournaments/1')
    end
  end

  describe 'the game-scoped users resource, scoped to show' do
    it 'reaches show' do
      expect_route(method: :get, path: '/PTCG/users/1', to: 'users#show', game: 'PTCG', id: '1')
    end

    it 'leaves index unreachable' do
      expect_no_route(method: :get, path: '/PTCG/users')
    end

    it 'leaves create unreachable' do
      expect_no_route(method: :post, path: '/PTCG/users')
    end

    it 'leaves edit unreachable' do
      expect_no_route(method: :get, path: '/PTCG/users/1/edit')
    end

    it 'leaves update unreachable' do
      expect_no_route(method: :patch, path: '/PTCG/users/1')
    end

    it 'leaves destroy unreachable' do
      expect_no_route(method: :delete, path: '/PTCG/users/1')
    end
  end

  describe 'the game-scoped salary drafts resource, scoped to index and show' do
    it 'reaches index' do
      expect_route(method: :get, path: '/PTCG/salary_drafts', to: 'salary_drafts#index', game: 'PTCG')
    end

    it 'reaches show' do
      expect_route(method: :get, path: '/PTCG/salary_drafts/1', to: 'salary_drafts#show', game: 'PTCG', id: '1')
    end

    it 'leaves create unreachable' do
      expect_no_route(method: :post, path: '/PTCG/salary_drafts')
    end

    it 'leaves edit unreachable' do
      expect_no_route(method: :get, path: '/PTCG/salary_drafts/1/edit')
    end

    it 'leaves update unreachable' do
      expect_no_route(method: :patch, path: '/PTCG/salary_drafts/1')
    end

    it 'leaves destroy unreachable' do
      expect_no_route(method: :delete, path: '/PTCG/salary_drafts/1')
    end
  end

  describe 'admin/data_subject_requests, scoped to index and show' do
    it 'reaches index' do
      expect_route(method: :get, path: '/admin/data_subject_requests', to: 'admin/data_subject_requests#index')
    end

    it 'reaches show' do
      expect_route(method: :get, path: '/admin/data_subject_requests/1', to: 'admin/data_subject_requests#show',
                   id: '1')
    end

    it 'leaves create unreachable' do
      expect_no_route(method: :post, path: '/admin/data_subject_requests')
    end

    it 'leaves edit unreachable' do
      expect_no_route(method: :get, path: '/admin/data_subject_requests/1/edit')
    end

    it 'leaves destroy unreachable' do
      expect_no_route(method: :delete, path: '/admin/data_subject_requests/1')
    end
  end

  describe 'data_subject_requests, scoped to new and create' do
    it 'reaches new' do
      expect_route(method: :get, path: '/data_subject_requests/new', to: 'data_subject_requests#new')
    end

    it 'reaches create' do
      expect_route(method: :post, path: '/data_subject_requests', to: 'data_subject_requests#create')
    end

    # index is not declared here, but the path still matches something: the
    # public, game-scoped root route, treating the literal path segment
    # "data_subject_requests" as its :game.
    it 'falls through index to the game home route' do
      expect_route(method: :get, path: '/data_subject_requests', to: 'pages#home', game: 'data_subject_requests')
    end

    it 'leaves show unreachable' do
      expect_no_route(method: :get, path: '/data_subject_requests/1')
    end
  end

  describe 'the game-scoped rosters resource, scoped to everything but index and new' do
    it 'reaches show' do
      expect_route(method: :get, path: '/PTCG/rosters/1', to: 'rosters#show', game: 'PTCG', id: '1')
    end

    it 'reaches edit' do
      expect_route(method: :get, path: '/PTCG/rosters/1/edit', to: 'rosters#edit', game: 'PTCG', id: '1')
    end

    it 'reaches create' do
      expect_route(method: :post, path: '/PTCG/rosters', to: 'rosters#create', game: 'PTCG')
    end

    it 'reaches update' do
      expect_route(method: :patch, path: '/PTCG/rosters/1', to: 'rosters#update', game: 'PTCG', id: '1')
    end

    it 'reaches destroy' do
      expect_route(method: :delete, path: '/PTCG/rosters/1', to: 'rosters#destroy', game: 'PTCG', id: '1')
    end

    it 'leaves index unreachable' do
      expect_no_route(method: :get, path: '/PTCG/rosters')
    end
  end
end
