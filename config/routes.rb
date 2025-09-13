Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api/docs"
  mount Rswag::Api::Engine => "/api/docs"

  devise_for :admins, path: "api/v1/admins", controllers: {
    sessions: "api/v1/admins/sessions"
  }

  namespace :api do
    namespace :v1 do
      namespace :admins do
        get "home", to: "dashboard#home"
      end
    end
  end
end
