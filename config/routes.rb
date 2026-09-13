Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'users/registrations' }
  resource :profile, only: %i[edit update]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  root "pages#landing"

  get "privacy" => "pages#privacy"
  get "terms" => "pages#terms"
  get "player-information" => "pages#player_information", as: :player_information

  namespace :admin do
    root "games#index"
    resources :users, only: %i[index show]
    resources :participations, only: %i[index show]
    resources :salary_drafts do
      post :complete, on: :member
    end
    resources :external_requests, only: %i[index show]
    resources :games, only: %i[index show], constraints: { id: %r{[^/]+} }
    resources :tournaments, only: %i[index show update]
    resources :players, only: %i[index show]
    resources :score_modifiers

    namespace :api do
      resources :external_imports, only: :create
      resources :player_season_modifiers, only: %i[create destroy]
      resources :tournaments, only: [] do
        resource :results, only: :update, controller: 'tournaments/results'
      end
    end
  end

  # A verb the admin namespace above doesn't declare for a given path falls
  # through to here, and a bare [^/]+ constraint would accept any string as
  # :game - including the literal "admin", silently landing an admin-only
  # verb on this public controller instead of 404ing. Every real Game id is
  # uppercase (see the Game factory and every seeded id in the codebase), so
  # requiring that shape both matches real usage and rules "admin" out.
  # Don't replace this with a regexp lookahead that excludes "admin" by
  # name instead: Rails' route matcher doesn't support lookaheads in a
  # requirement and fails deep inside route recognition (a NoMethodError,
  # not a clean non-match) the first time a path exercises one.
  scope ':game', as: 'game', constraints: { game: /[A-Z0-9]+/ } do
    root "pages#home"
    resources :players, only: :index
    resources :tournaments, only: :index
    resources :users, only: :show
    resources :salary_drafts, only: %i[index show]
    resources :participations, only: %i[destroy create show index update]
    resources :rosters, only: %i[show edit create update destroy]
  end

end
