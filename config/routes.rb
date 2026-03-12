require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  Sidekiq::Web.use ActionDispatch::Cookies
  Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_sidekiq_session"
  mount Sidekiq::Web => "/sidekiq"
  mount ActionCable.server => "/cable"
  mount Rswag::Ui::Engine => "/api/docs"
  mount Rswag::Api::Engine => "/api/docs"

  # Health check endpoint for load balancer
  get "health", to: "health#index"

  devise_for :admins, path: "api/v1/admins", controllers: {
    sessions: "api/v1/admins/sessions"
  }

  namespace :api do
    namespace :v1 do
      # Public endpoints (no auth)
      resources :public_feedbacks, only: [:index]
      get "leaderboard", to: "leaderboard#index"
      resources :devtools_logs, only: [:create]
      get "ip_check", to: "ip_check#show"

      # User OAuth & API
      namespace :users do
        post "auth_google", to: "omniauths#auth_google"
        get "me", to: "dashboard#me"
        resource :setting, only: [:show, :update]
        resources :srs_cards, only: [:index, :show, :create, :update, :destroy] do
          collection { get :summary }
        end
        resources :review_logs, only: [:index, :show, :create] do
          collection do
            get :stats
          end
        end
        resources :roadmap_day_progresses, only: [:index, :show, :create, :update, :destroy]
        resources :custom_roadmaps, only: [:index, :show, :create, :update, :destroy] do
          resources :day_progresses, only: [:index, :create],
                    controller: "custom_roadmap_day_progresses"
        end
        resources :custom_vocab_items, only: [:index, :show, :create, :update, :destroy]
        resources :vocab_sets, only: [:index, :show, :create, :update, :destroy] do
          member do
            put :sync_items
          end
        end
        resources :tango_lesson_progresses, only: [:index, :create]
        resources :jlpt_test_results, only: [:index, :create]
        resources :feedbacks, only: [:index, :show, :create]
        resources :notifications, only: [:index], controller: "notifications" do
          collection do
            patch :mark_read
          end
          member do
            patch :mark_read
          end
        end
        get "chat_status", to: "chat_status#show"
        post "chat_messages", to: "chat_status#record_message"
        resources :quick_replies, only: [:index]
        resources :page_views, only: [:create]
        post "study_alerts", to: "study_alerts#create"
        post "srs_reset", to: "srs_reset#create"
      end

      # Admin management
      namespace :admins do
        get "me", to: "dashboard#me"
        get "analytics", to: "dashboard#analytics"
        post "cache_sync", to: "dashboard#cache_sync"
        get "revenue", to: "revenue#index"
        resources :feedbacks, only: [:index, :show, :update, :destroy] do
          resources :replies, only: [:create], controller: "feedback_replies"
        end
        resources :admin_notifications, only: [:index, :show, :create, :update, :destroy] do
          collection do
            patch :mark_read
          end
          member do
            patch :mark_read
          end
        end
        resources :user_notifications, only: [:index, :show, :create, :update, :destroy]
        resources :quick_replies
        resources :devtools_logs, only: [:index]
        resources :blocked_ips, only: [:index, :create, :destroy]
        resources :chat_rooms, only: [:index, :update], param: :uid
        resources :users, only: [:index, :show, :update, :destroy] do
          member do
            post :recalculate_counters
          end
          resources :srs_cards, only: [:index, :destroy], controller: "user_srs_cards" do
            member do
              patch :reset
            end
          end
          resources :review_logs, only: [:index], controller: "user_review_logs"
          resources :roadmap_day_progresses, only: [:index], controller: "user_roadmap_day_progresses"
          resources :custom_vocab_items, only: [:index, :destroy], controller: "user_custom_vocab_items"
          resources :vocab_sets, only: [:index, :destroy], controller: "user_vocab_sets" do
            member do
              delete :remove_item
            end
          end
          resources :tango_lesson_progresses, only: [:index], controller: "user_tango_lesson_progresses"
          resources :jlpt_test_results, only: [:index], controller: "user_jlpt_test_results"
          resources :feedbacks, only: [:index], controller: "user_feedbacks"
          resources :login_activities, only: [:index], controller: "user_login_activities"
          resources :page_views, only: [:index], controller: "user_page_views"
          resources :devtools_logs, only: [:index], controller: "devtools_logs"
          resource :setting, only: [:show], controller: "user_settings"
        end
      end
    end
  end
end
