# config/environments/development.rb

Rails.application.configure do
  # Reload code on every request (slows down response time but perfect for development)
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # ActionMailer settings (for development email preview)
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :letter_opener

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Use an evented file watcher to asynchronously detect changes in source code, routes, locales, etc.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # ActionCable settings for development
  config.action_cable.url = "ws://localhost:3000/cable"
  config.action_cable.allowed_request_origins = ["http://localhost:3000", /http:\/\/127\.0\.0\.1:.*/]

  # Enable full error reports for ActionCable
  config.action_cable.log_tags = [ :action_cable, -> request { request.uuid } ]

  # Log formatting for easier debugging
  config.log_level = :debug
  config.log_formatter = ::Logger::Formatter.new
  config.colorize_logging = true if config.respond_to?(:colorize_logging)

  # Performance monitoring: show detailed runtime for queries
  config.active_record.verbose_query_logs = true

  # Development-specific middleware for better debugging
  config.middleware.insert_after ActionDispatch::DebugExceptions, Rack::LiveReload

  # Allow websocket requests from local and tunneling services like ngrok
  config.web_socket_server_url = "ws://localhost:3000/cable"
end
