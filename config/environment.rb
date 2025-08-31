# config/environment.rb

# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

# ------------------------------
# Custom environment configurations for PixelCanvas
# ------------------------------

# Ensure Bundler loads all gems from Gemfile
require "bundler/setup" # Set up gems listed in the Gemfile.
Bundler.require(*Rails.groups)

# Configure default time zone and locale
Rails.application.configure do
  config.time_zone = ENV.fetch("TIME_ZONE") { "UTC" }
  config.active_record.default_timezone = :utc
  config.i18n.default_locale = :en
  config.i18n.fallbacks = true

  # Enable automatic connection pool reaping for Heroku
  config.active_record.pool = ENV.fetch("RAILS_MAX_THREADS") { 5 }
  config.active_record.reaping_frequency = ENV.fetch("DB_REAP_FREQ") { 10 }

  # Ensure database connections are maintained
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end

  # Set default URL options for ActionMailer
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST") { "localhost" },
    protocol: ENV.fetch("APP_PROTOCOL") { "http" }
  }

  # Preload ActionCable for WebSockets
  config.action_cable.mount_path = "/cable"
  config.action_cable.allowed_request_origins = [
    %r{https?://.*},
    %r{ws?://.*}
  ]
  config.action_cable.disable_request_forgery_protection = false

  # Force SSL in production
  config.force_ssl = ENV.fetch("FORCE_SSL") { Rails.env.production? }

  # Enable log tags for request id and user
  config.log_tags = [:request_id, ->(req) { req.session[:user_id] }]

  # Configure ActiveStorage to use cloud service in production
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE") { :local }

  # Preload any custom initializers
  Dir[Rails.root.join("config/initializers/**/*.rb")].each { |file| require file }
end

# Set global constants
PIXEL_CANVAS_SIZE = 100
PIXEL_DRAW_DELAY = 10 # seconds per pixel
FREE_COLORS_COUNT = 30
