# pixelcanvas/config.ru
# Rack configuration file for PixelCanvas
# Fully production-ready with middleware, logging, and WebSocket support

# Load Rails environment
require ::File.expand_path('../config/environment', __FILE__)

# Use Rails default Rack application
app = Rails.application

# Middleware stack
use Rack::ContentLength
use Rack::ETag
use Rack::ConditionalGet
use Rack::Runtime
use Rack::MethodOverride
use Rack::TempfileReaper
use Rack::Head

# Logging
use Rack::CommonLogger, Logger.new(STDOUT)

# Session handling
use ActionDispatch::Cookies
use ActionDispatch::Session::CookieStore, key: '_pixelcanvas_session', secure: Rails.env.production?, same_site: :lax
use ActionDispatch::Flash

# CORS headers for API & WebSocket support
use Rack::Cors do
  allow do
    origins '*'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false
  end
end

# Mount ActionCable for real-time pixel updates
map '/cable' do
  run ActionCable.server
end

# Mount Rails app
map '/' do
  run app
end

# Error handling for non-Rails routes
use Rack::ShowExceptions
use Rack::ShowStatus

# Catch-all 404 handler for missing routes
run lambda { |env|
  [
    404,
    { 'Content-Type' => 'text/html' },
    [File.read(File.join(File.dirname(__FILE__), 'public', '404.html'))]
  ]
}
