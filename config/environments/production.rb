Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.assets.compile = false
  config.log_level = :debug
  config.log_tags  = [:request_id]
  config.force_ssl = ENV.fetch("FORCE_SSL", "true") == "true"

  config.active_storage.service = :local
  config.active_job.queue_adapter = :sidekiq

  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_HOST'],
    port: ENV['SMTP_PORT'],
    domain: ENV['SMTP_DOMAIN'],
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: :plain,
    enable_starttls_auto: true
  }

  config.i18n.fallbacks = true
  config.cache_store = :memory_store
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
end
