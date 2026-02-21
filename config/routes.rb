Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api/docs"
  mount Rswag::Api::Engine => "/api/docs"

  # Health check endpoint for load balancer
  get "health", to: "health#index"

  devise_for :admins, path: "api/v1/admins", controllers: {
    sessions: "api/v1/admins/sessions"
  }

  namespace :api do
    namespace :v1 do
      # User OAuth
      namespace :users do
        post "auth_google", to: "omniauths#auth_google"
      end

      # Admin management
      namespace :admins do
        get "me", to: "dashboard#me"
        resources :users, only: [:index, :show, :update, :destroy]
      end
    end
  end
end
