Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  # ログイン中はメモ一覧をトップにする
  authenticated :user do
    root to: "memos#index", as: :authenticated_root
  end

  # 未ログイン時のトップページ（説明LP）
  root to: "pages#home"

  # メモ（showは使わない想定）
  resources :memos, except: [:show]

  # フッター
  get "/terms",   to: "pages#terms"
  get "/privacy", to: "pages#privacy"
  get "/contact", to: "pages#contact"

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check
end
