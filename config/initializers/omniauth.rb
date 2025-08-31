# config/initializers/omniauth.rb

Rails.application.config.middleware.use OmniAuth::Builder do
  # Google OAuth2 configuration
  provider :google_oauth2,
           ENV.fetch('GOOGLE_CLIENT_ID'),
           ENV.fetch('GOOGLE_CLIENT_SECRET'),
           {
             scope: 'email,profile',
             access_type: 'offline', # to allow refresh tokens
             prompt: 'consent',      # always prompt for consent
             image_aspect_ratio: 'square',
             image_size: 200,
             skip_jwt: true
           }

  # Example for future multi-provider support
  # provider :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET'], scope: "user:email"
  # provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'], scope: 'email'
end

# Handle OmniAuth failures gracefully
OmniAuth.config.on_failure = Proc.new { |env|
  # Store error message in flash and redirect to root
  message = env['omniauth.error']&.error_reason || "Authentication failed"
  strategy = env['omniauth.error.strategy'].name rescue "unknown"
  Rails.logger.warn "[OmniAuth Failure] Strategy: #{strategy}, Message: #{message}"

  # Redirect to the login page
  Rack::Response.new(['302 Moved'], 302, 'Location' => "/?error=#{Rack::Utils.escape(message)}").finish
}

# Optional: Force SSL redirects for OAuth callbacks in production
if Rails.env.production?
  OmniAuth.config.full_host = Rails.application.config.action_controller.default_url_options[:host] || 'https://yourdomain.com'
  OmniAuth.config.allowed_request_methods = [:get, :post]
end

# Optional: Serialize additional user info from Google
OmniAuth.config.before_request_phase do |env|
  request = Rack::Request.new(env)
  Rails.logger.info "[OmniAuth] Request phase started for #{request.path}"
end
