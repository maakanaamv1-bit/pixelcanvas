# pixelcanvas/main.rb

# Load Rails
require_relative 'config/environment'

# Load gems
require 'bundler/setup'
Bundler.require(:default, Rails.env)

# Initialize Rails application
Rails.application.initialize!

# Stripe configuration
Stripe.api_key = ENV['STRIPE_SECRET_KEY']

# OmniAuth configuration
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], {
    scope: 'email,profile',
    prompt: 'select_account'
  }
end

# Mount ActionCable server
Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  # Root route
  root to: 'home#index'

  # Auth routes
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/logout', to: 'sessions#destroy', as: :logout

  # Pixel actions
  resources :pixels, only: [:index, :create, :update]

  # Leaderboard
  resources :leaderboards, only: [:index]

  # User profiles
  resources :profiles, only: [:show, :edit, :update]

  # Purchases
  resources :purchases, only: [:create]

  # Groups
  resources :groups, only: [:index, :show, :create, :update, :destroy]
  resources :group_memberships, only: [:create, :destroy]

  # Chat messages
  resources :chat_messages, only: [:index, :create]
end

# Sidekiq configuration
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }
end

# ActionCable channel for real-time pixels
class PixelsChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'pixels_channel'
  end

  def receive(data)
    pixel = Pixel.find_or_initialize_by(x: data['x'], y: data['y'])
    pixel.color = data['color']
    pixel.user_id = current_user.id if current_user
    pixel.save!
    ActionCable.server.broadcast('pixels_channel', pixel: pixel.as_json)
  end
end

# ActionCable channel for chat
class ChatMessagesChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'chat_messages_channel'
  end

  def receive(data)
    message = ChatMessage.create!(user: current_user, content: data['content'])
    ActionCable.server.broadcast('chat_messages_channel', message: message.as_json(include: :user))
  end
end

# Start the Rails server if executed directly
if __FILE__ == $PROGRAM_NAME
  require 'rails/commands/server'
  Rails::Server.new.tap do |server|
    # Default port 3000
    server.options[:Port] = ENV.fetch('PORT', 3000)
    server.start
  end
end
