Rails.application.routes.draw do
  get "pages/terms"
  get "pages/privacy"
  get "pages/contact"
  get "memos/index"
  get "memos/new"
  get "memos/edit"
  devise_for :users, controllers: { registrations: "users/registrations" }
  resources :memos, except: [:show]

  #フッター
  get "/terms",   to: "pages#terms"
  get "/privacy", to: "pages#privacy"
  get "/contact", to: "pages#contact"

  root "memos#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
