# config/environments/production.rb

Rails.application.configure do
  # Cache classes and eager load code for maximum performance
  config.cache_classes = true
  config.eager_load = true

  # Full error reports are disabled in production
  config.consider_all_requests_local = false

  # Enable caching with Redis or memory store
  config.action_controller.perform_caching = true
  config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'], expires_in: 90.minutes } rescue :memory_store

  # Serve static files from /public if ENV['RAILS_SERVE_STATIC_FILES'] is set
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass
  config.assets.compile = false

  # Asset digests allow far-future HTTP expiration dates
  config.assets.digest = true

  # Force all access to the app over SSL
  config.force_ssl = true

  # Use default logging formatter so PID and timestamp are included
  config.log_formatter = ::Logger::Formatter.new
  config.log_level = :info

  # Enable logging to STDOUT for Heroku
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Use Redis for ActionCable in production
  config.action_cable.url = ENV['ACTION_CABLE_URL'] || "wss://#{ENV['DOMAIN_NAME']}/cable"
  config.action_cable.allowed_request_origins = [ "https://#{ENV['DOMAIN_NAME']}", /https:\/\/.*\.#{ENV['DOMAIN_NAME']}/ ]

  # ActiveStorage configuration for production (S3 example)
  config.active_storage.service = :amazon

  # Mailer configuration (example for SendGrid)
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_ADDRESS'] || 'smtp.sendgrid.net',
    port: ENV['SMTP_PORT'] || 587,
    domain: ENV['DOMAIN_NAME'],
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: :plain,
    enable_starttls_auto: true
  }
  config.action_mailer.default_url_options = { host: ENV['DOMAIN_NAME'], protocol: 'https' }

  # I18n fallback to default locale
  config.i18n.fallbacks = true

  # Deprecation notices
  config.active_support.deprecation = :notify

  # Log database query runtime
  config.active_record.verbose_query_logs = false

  # Enable serving assets from a CDN if provided
  config.asset_host = ENV['ASSET_HOST'] if ENV['ASSET_HOST'].present?

  # Background jobs
  config.active_job.queue_adapter = :sidekiq

  # Enable Rack::Cache or other reverse proxy caching if needed
  # config.action_dispatch.rack_cache = true
end
