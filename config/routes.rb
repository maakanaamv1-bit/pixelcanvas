# config/routes.rb

Rails.application.routes.draw do
  # -----------------------
  # Root / Home
  # -----------------------
  root to: "home#index"

  # -----------------------
  # Authentication (Google OAuth)
  # -----------------------
  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: redirect("/")
  delete "/logout", to: "sessions#destroy", as: :logout

  # -----------------------
  # Pixel drawing
  # -----------------------
  resources :pixels, only: [:create, :index, :update, :destroy] do
    collection do
      get "history"        # For historical pixel queries
      get "user_stats/:user_id", to: "pixels#user_stats", as: :user_stats
    end
  end

  # -----------------------
  # Leaderboards
  # -----------------------
  resources :leaderboards, only: [:index] do
    collection do
      get "daily"
      get "monthly"
      get "yearly"
    end
  end

  # -----------------------
  # User profiles
  # -----------------------
  resources :profiles, only: [:show, :edit, :update] do
    member do
      get "pixels_drawn"
      get "colors_owned"
    end
  end

  # -----------------------
  # Chat system
  # -----------------------
  resources :chat_messages, only: [:create, :index]

  # -----------------------
  # Groups / guilds
  # -----------------------
  resources :groups do
    resources :group_memberships, only: [:create, :destroy]
  end

  # -----------------------
  # Stripe webhooks
  # -----------------------
  post "/stripe/webhook", to: "stripe_webhook#create"

  # -----------------------
  # ActionCable (WebSocket)
  # -----------------------
  mount ActionCable.server => "/cable"

  # -----------------------
  # API / JSON namespace (future-ready)
  # -----------------------
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :pixels, only: [:create, :index]
      resources :leaderboards, only: [:index]
      resources :profiles, only: [:show, :update]
      resources :chat_messages, only: [:create, :index]
      resources :groups, only: [:index, :show]
    end
  end

  # -----------------------
  # Fallback route
  # -----------------------
  get "*path", to: redirect("/")
end
