# pixelcanvas/Gemfile
source 'https://rubygems.org'

# Rails core
gem 'rails', '~> 7.1.0'
gem 'pg', '>= 1.3'                   # PostgreSQL database
gem 'puma', '~> 6.0'                 # Web server for Heroku
gem 'sass-rails', '>= 6'             # CSS preprocessor
gem 'turbo-rails'                    # Hotwire Turbo for fast front-end
gem 'stimulus-rails'                 # Stimulus JS for interactions
gem 'jbuilder', '~> 2.11'            # JSON views
gem 'webpacker', '~> 5.0'            # JS bundling

# Authentication & OAuth
gem 'devise', '~> 4.9'               # User authentication
gem 'omniauth-google-oauth2', '~> 2.2' # Google OAuth login

# Payments
gem 'stripe', '~> 6.0'               # Stripe payment processing

# Real-time features
gem 'redis', '~> 6.2'                # Redis for ActionCable & caching
gem 'actioncable', '~> 7.1'          # WebSocket server for live canvas

# Image uploads / storage
gem 'image_processing', '~> 1.14'   # For ActiveStorage image processing
gem 'mini_magick', '~> 4.12'         # ImageMagick wrapper
gem 'aws-sdk-s3', '~> 1.115'         # S3 storage support

# Background jobs
gem 'sidekiq', '~> 7.0'              # Background job processing
gem 'sidekiq-cron', '~> 1.2'         # Cron scheduling for Sidekiq

# Authorization
gem 'cancancan', '~> 3.3'            # User permissions

# Pagination and helpers
gem 'kaminari', '~> 1.3'             # Pagination for leaderboards
gem 'friendly_id', '~> 5.4'          # Slugs for user profiles

# Utilities
gem 'dotenv-rails', groups: [:development, :test] # Environment variables
gem 'faker', '~> 3.1', groups: [:development, :test] # Fake data
gem 'pry-rails', groups: [:development, :test]   # Debugging

# Development & Testing
group :development do
  gem 'web-console', '>= 4.2'
  gem 'listen', '~> 3.7'
  gem 'spring'
end

group :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'capybara', '>= 3.36'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

# Heroku deployment
gem 'rails_12factor', group: :production
