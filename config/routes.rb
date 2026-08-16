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
    resources :games, only: %i[index show], constraints: { id: %r{[^/]+} }

    namespace :api do
      resources :external_imports, only: :create
    end
  end

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
