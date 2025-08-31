# frozen_string_literal: true

# =============================================================================
# PixelCanvas Rails Application Configuration
# Purpose: Central configuration for Rails 8 app
# Author: Generated for Heroku deployment
# =============================================================================

require_relative "boot"

# Load Rails frameworks individually (for granular control)
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Gems loaded via Bundler
Bundler.require(*Rails.groups)

module PixelCanvas
  class Application < Rails::Application
    # -----------------------------
    # General configuration
    # -----------------------------
    config.load_defaults 8.0
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc
    config.encoding = "utf-8"
    config.filter_parameters += [:password, :password_confirmation, :token]

    # -----------------------------
    # Eager load and autoload paths
    # -----------------------------
    config.eager_load_paths << Rails.root.join("lib")
    config.autoload_paths += %W[#{config.root}/extras #{config.root}/services]

    # -----------------------------
    # Middleware
    # -----------------------------
    config.middleware.use Rack::Attack if defined?(Rack::Attack)
    config.middleware.use Rack::Deflater
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"
        resource "*", headers: :any, methods: [:get, :post, :patch, :put, :delete, :options]
      end
    end

    # -----------------------------
    # Active Job
    # -----------------------------
    config.active_job.queue_adapter = :sidekiq
    config.active_job.queue_name_prefix = "#{Rails.env}_pixel_canvas"

    # -----------------------------
    # Generators configuration
    # -----------------------------
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.template_engine :erb
      g.test_framework :rspec, fixtures: true, view_specs: false, helper_specs: false
      g.assets false
      g.helper false
    end

    # -----------------------------
    # Active Storage
    # -----------------------------
    config.active_storage.service = :local

    # -----------------------------
    # Action Mailer
    # -----------------------------
    config.action_mailer.perform_caching = false
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_HOST", "smtp.example.com"),
      port: ENV.fetch("SMTP_PORT", 587),
      domain: ENV.fetch("SMTP_DOMAIN", "example.com"),
      user_name: ENV["SMTP_USERNAME"],
      password: ENV["SMTP_PASSWORD"],
      authentication: :plain,
      enable_starttls_auto: true
    }

    # -----------------------------
    # Action Cable
    # -----------------------------
    config.action_cable.mount_path = "/cable"
    config.action_cable.allowed_request_origins = [%r{https?://.*}]

    # -----------------------------
    # Security
    # -----------------------------
    config.force_ssl = ENV.fetch("FORCE_SSL", "true") == "true"
    config.hosts << "your-app.herokuapp.com"

    # -----------------------------
    # Logging
    # -----------------------------
    config.log_level = :debug
    config.log_tags  = [:request_id]
    config.logger    = ActiveSupport::Logger.new(STDOUT)
    config.logger.formatter = ::Logger::Formatter.new

    # -----------------------------
    # Custom hooks
    # -----------------------------
    config.after_initialize do
      puts "[PixelCanvas] Rails initialized in #{Rails.env} mode"
    end

    # -----------------------------
    # Internationalization
    # -----------------------------
    config.i18n.default_locale = :en
    config.i18n.available_locales = [:en, :es, :fr, :de]
    config.i18n.fallbacks = true

    # -----------------------------
    # Cache store
    # -----------------------------
    config.cache_store = :memory_store, { size: 64.megabytes }

    # -----------------------------
    # Custom error pages
    # -----------------------------
    config.exceptions_app = self.routes
  end
end
