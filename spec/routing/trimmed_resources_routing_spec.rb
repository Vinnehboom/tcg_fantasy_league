require 'rails_helper'

RSpec.describe 'Trimmed resources' do
  def assert_routable(method:, path:, to:, **params)
    expect({ method => path }).to route_to(to, **params)
  end

  def assert_not_routable(method:, path:)
    expect({ method => path }).not_to be_routable
  end

  describe 'admin users' do
    it 'routes index' do
      assert_routable(method: :get, path: '/admin/users', to: 'admin/users#index')
    end

    it 'routes show' do
      assert_routable(method: :get, path: '/admin/users/1', to: 'admin/users#show', id: '1')
    end

    it 'does not route create' do
      assert_not_routable(method: :post, path: '/admin/users')
    end

    it 'does not route edit' do
      assert_not_routable(method: :get, path: '/admin/users/1/edit')
    end

    it 'does not route update' do
      assert_not_routable(method: :patch, path: '/admin/users/1')
    end

    it 'does not route destroy' do
      assert_not_routable(method: :delete, path: '/admin/users/1')
    end
  end

  describe 'admin participations' do
    it 'routes index' do
      assert_routable(method: :get, path: '/admin/participations', to: 'admin/participations#index')
    end

    it 'routes show' do
      assert_routable(method: :get, path: '/admin/participations/1', to: 'admin/participations#show', id: '1')
    end

    it 'does not route create' do
      assert_not_routable(method: :post, path: '/admin/participations')
    end

    it 'does not route edit' do
      assert_not_routable(method: :get, path: '/admin/participations/1/edit')
    end

    it 'does not route update' do
      assert_not_routable(method: :patch, path: '/admin/participations/1')
    end

    it 'does not route destroy' do
      assert_not_routable(method: :delete, path: '/admin/participations/1')
    end
  end

  describe 'game-scoped players' do
    it 'routes index' do
      assert_routable(method: :get, path: '/PTCG/players', to: 'players#index', game: 'PTCG')
    end

    it 'does not route new' do
      assert_not_routable(method: :get, path: '/PTCG/players/new')
    end

    it 'does not route create' do
      assert_not_routable(method: :post, path: '/PTCG/players')
    end

    it 'does not route show' do
      assert_not_routable(method: :get, path: '/PTCG/players/1')
    end

    it 'does not route edit' do
      assert_not_routable(method: :get, path: '/PTCG/players/1/edit')
    end

    it 'does not route update' do
      assert_not_routable(method: :patch, path: '/PTCG/players/1')
    end

    it 'does not route destroy' do
      assert_not_routable(method: :delete, path: '/PTCG/players/1')
    end
  end

  describe 'game-scoped tournaments' do
    it 'routes index' do
      assert_routable(method: :get, path: '/PTCG/tournaments', to: 'tournaments#index', game: 'PTCG')
    end

    it 'does not route new' do
      assert_not_routable(method: :get, path: '/PTCG/tournaments/new')
    end

    it 'does not route create' do
      assert_not_routable(method: :post, path: '/PTCG/tournaments')
    end

    it 'does not route show' do
      assert_not_routable(method: :get, path: '/PTCG/tournaments/1')
    end

    it 'does not route edit' do
      assert_not_routable(method: :get, path: '/PTCG/tournaments/1/edit')
    end

    it 'does not route update' do
      assert_not_routable(method: :patch, path: '/PTCG/tournaments/1')
    end

    it 'does not route destroy' do
      assert_not_routable(method: :delete, path: '/PTCG/tournaments/1')
    end
  end

  describe 'game-scoped users' do
    it 'routes show' do
      assert_routable(method: :get, path: '/PTCG/users/1', to: 'users#show', game: 'PTCG', id: '1')
    end

    it 'does not route index' do
      assert_not_routable(method: :get, path: '/PTCG/users')
    end

    it 'does not route create' do
      assert_not_routable(method: :post, path: '/PTCG/users')
    end

    it 'does not route edit' do
      assert_not_routable(method: :get, path: '/PTCG/users/1/edit')
    end

    it 'does not route update' do
      assert_not_routable(method: :patch, path: '/PTCG/users/1')
    end

    it 'does not route destroy' do
      assert_not_routable(method: :delete, path: '/PTCG/users/1')
    end
  end

  describe 'game-scoped rosters' do
    it 'routes show' do
      assert_routable(method: :get, path: '/PTCG/rosters/1', to: 'rosters#show', game: 'PTCG', id: '1')
    end

    it 'routes edit' do
      assert_routable(method: :get, path: '/PTCG/rosters/1/edit', to: 'rosters#edit', game: 'PTCG', id: '1')
    end

    it 'routes create' do
      assert_routable(method: :post, path: '/PTCG/rosters', to: 'rosters#create', game: 'PTCG')
    end

    it 'routes update' do
      assert_routable(method: :patch, path: '/PTCG/rosters/1', to: 'rosters#update', game: 'PTCG', id: '1')
    end

    it 'routes destroy' do
      assert_routable(method: :delete, path: '/PTCG/rosters/1', to: 'rosters#destroy', game: 'PTCG', id: '1')
    end

    it 'does not route index' do
      assert_not_routable(method: :get, path: '/PTCG/rosters')
    end
  end
end
