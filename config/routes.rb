Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Root path
  root "home#index"

  # Authentication routes
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  get '/signin', to: 'sessions#new', as: :signin
  get '/signout', to: 'sessions#destroy', as: :signout

  # YouTube channels and videos
  resources :channels, only: [:index] do
    resources :videos, only: [:index, :edit, :update] do
      member do
        post :sync_from_plan
        post :toggle_privacy
      end
    end
  end
  
  # Planning Center routes
  namespace :planning_center do
    resources :service_types, only: [:index, :show]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
