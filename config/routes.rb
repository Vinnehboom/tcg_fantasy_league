Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  root "pages#landing"

  namespace :admin do
    root "users#index"
    resources :users
    resources :participations
    resources :salary_drafts do
      post :complete, on: :member
    end
    resources :external_requests, only: %i[index show]
    # Same free-form-string-id constraint as the ':game' scope below -- the
    # default dynamic segment stops at "." and Game#id may contain one.
    resources :games, only: :show, constraints: { id: %r{[^/]+} }
  end

  # Internal API for frontend integrations (fetch/JS calls from admin pages) --
  # session-cookie-authenticated like the rest of the app, headless JSON/status
  # responses instead of views.
  namespace :api do
    resources :external_imports, only: :create
  end

  # Game#id is a free-form string primary key (e.g. seeded/import data may include
  # punctuation), so the default dynamic-segment matcher -- which stops at "." -- would
  # 422/404 on any game id containing a period. Explicitly allow anything but "/".
  scope ':game', as: 'game', constraints: { game: %r{[^/]+} } do
    root "pages#home"
    resources :players
    resources :tournaments
    resources :users
    resources :salary_drafts
    resources :participations, only: %i[destroy create show index update]
    resources :rosters
  end

end
