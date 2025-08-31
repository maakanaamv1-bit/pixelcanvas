# config/puma.rb

# Puma configuration file for PixelCanvas

# Threads configuration: min and max threads per worker
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Port configuration
port        ENV.fetch("PORT") { 3000 }

# Environment configuration
environment ENV.fetch("RAILS_ENV") { "development" }

# Workers (for clustered mode)
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Preload the application for faster worker spawn (important for ActionCable)
preload_app!

# Rackup file
rackup      DefaultRackup

# Specifies the path to the pidfile
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Allow puma to be restarted by `rails restart` command
plugin :tmp_restart

# -----------------------------
# Heroku-specific configurations
# -----------------------------

# Use environment variable to set number of threads for ActionCable
on_worker_boot do
  puts "Worker booting..."
  # Reconnect ActiveRecord to database
  ActiveRecord::Base.establish_connection

  # Ensure ActionCable Redis connection is initialized
  if defined?(ActionCable)
    redis_url = ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
    ActionCable.server.config.cable = { adapter: "redis", url: redis_url }
    puts "ActionCable Redis connected to #{redis_url}"
  end
end

# Graceful shutdown
before_fork do
  puts "Before fork: gracefully shutting down old workers"
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

# Allow longer wait for busy connections
worker_timeout ENV.fetch("WORKER_TIMEOUT") { 60 }

# Logging
stdout_redirect "log/puma.stdout.log", "log/puma.stderr.log", true
