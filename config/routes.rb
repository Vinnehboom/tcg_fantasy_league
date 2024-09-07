Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  root "pages#landing"

  scope ':game', as: 'game' do
    root "pages#home"
    resources :players
    resources :tournaments
    resources :users
    resources :salary_drafts
    resources :participations, only: %i[destroy create show index update]
    resources :rosters
  end

end
