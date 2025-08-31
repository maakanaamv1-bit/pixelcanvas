# config/environments/test.rb

Rails.application.configure do
  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise.  
  config.cache_classes = true
  config.eager_load = false # Avoid eager loading in tests for speed

  # Configure static file server for tests with Cache-Control for performance
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching for test reliability
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

  # Configure Action Mailer for tests
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  # Raise exceptions for pending migrations
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs
  config.active_record.verbose_query_logs = true

  # Configure test queue adapter for ActiveJob
  config.active_job.queue_adapter = :inline

  # ActionCable test configuration
  config.action_cable.url = "ws://localhost:3000/cable"
  config.action_cable.allowed_request_origins = [ /http:\/\/localhost:.*/ ]

  # Asset compilation for tests (simulate production asset pipeline)
  config.assets.compile = true
  config.assets.digest = true
  config.assets.debug = false

  # Enable I18n fallbacks for missing translations
  config.i18n.fallbacks = true

  # Enable full logging to STDOUT (optional for CI visibility)
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Test-specific feature flags
  config.x.pixel_limit = 100  # pixels per user in test
  config.x.free_colors_count = 30 # default free colors
end
