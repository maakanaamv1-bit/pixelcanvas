# config/application.rb
require_relative "boot"

require "rails"
# Pick the frameworks you want:
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
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PixelCanvas
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Timezone
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc

    # I18n (internationalization)
    config.i18n.default_locale = :en
    config.i18n.available_locales = [:en]
    config.i18n.fallbacks = true

    # Autoload paths for custom directories
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/app/services #{config.root}/app/jobs)

    # Middleware
    config.middleware.use Rack::Attack
    config.middleware.use Rack::Deflater
    config.middleware.use Rack::Runtime

    # Generators
    config.generators do |g|
      g.test_framework  :rspec, fixture: false
      g.assets          false
      g.helper          false
      g.jbuilder        true
    end

    # Active Storage
    config.active_storage.service = :local

    # Action Cable
    config.action_cable.mount_path = "/cable"
    config.action_cable.allowed_request_origins = [%r{https?://.*}]
    config.action_cable.disable_request_forgery_protection = false

    # Active Job
    config.active_job.queue_adapter = :sidekiq

    # Logging
    config.log_level = :info
    config.log_tags  = [:request_id]
    config.logger    = ActiveSupport::Logger.new(STDOUT)
    config.logger.formatter = ::Logger::Formatter.new

    # Eager load
    config.eager_load_paths += %W(#{config.root}/lib)

    # Assets
    config.assets.enabled = true
    config.assets.paths << Rails.root.join("app", "assets", "fonts")
    config.assets.precompile += %w( *.js *.css *.css.erb )

    # Security
    config.action_dispatch.cookies_same_site_protection = :strict
    config.action_controller.default_protect_from_forgery = true
    config.filter_parameters += [:password, :password_confirmation]

    # Custom config
    config.x.pixel_limit_per_minute = 60
    config.x.max_canvas_size = 100_000
    config.x.default_color = "#FFFFFF"

    # Email
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.perform_caching = false
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_ADDRESS", "smtp.sendgrid.net"),
      port: ENV.fetch("SMTP_PORT", 587),
      domain: ENV.fetch("SMTP_DOMAIN", "example.com"),
      user_name: ENV["SMTP_USERNAME"],
      password: ENV["SMTP_PASSWORD"],
      authentication: :plain,
      enable_starttls_auto: true
    }

    # Custom exception handling
    config.exceptions_app = self.routes

    # Allow embedding in iframe for specific origins
    config.action_dispatch.default_headers.merge!({
      "X-Frame-Options" => "ALLOW-FROM https://pixelcanvas.example.com"
    })
  end
end
