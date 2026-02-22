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
      # User OAuth & API
      namespace :users do
        post "auth_google", to: "omniauths#auth_google"
        get "me", to: "dashboard#me"
        resource :setting, only: [:show, :update]
        resources :srs_cards, only: [:index, :show, :create, :update, :destroy]
        resources :review_logs, only: [:index, :show, :create]
        resources :roadmap_day_progresses, only: [:index, :show, :create, :update, :destroy]
        resources :custom_vocab_items, only: [:index, :show, :create, :update, :destroy]
        resources :feedbacks, only: [:index, :show, :create]
      end

      # Admin management
      namespace :admins do
        get "me", to: "dashboard#me"
        resources :feedbacks, only: [:index, :show, :update, :destroy]
        resources :users, only: [:index, :show, :update, :destroy] do
          resources :srs_cards, only: [:index], controller: "user_srs_cards"
          resources :review_logs, only: [:index], controller: "user_review_logs"
          resources :roadmap_day_progresses, only: [:index], controller: "user_roadmap_day_progresses"
          resources :custom_vocab_items, only: [:index], controller: "user_custom_vocab_items"
          resources :feedbacks, only: [:index], controller: "user_feedbacks"
          resource :setting, only: [:show], controller: "user_settings"
        end
      end
    end
  end
end
