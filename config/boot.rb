# config/boot.rb

# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

# Load environment variables from .env files if using dotenv-rails
if defined?(Dotenv)
  Dotenv.load('.env', ".env.#{ENV['RAILS_ENV']}")
end

# Check Ruby version
required_ruby_version = Gem::Requirement.new('>= 3.2.0')
unless required_ruby_version.satisfied_by?(Gem::Version.new(RUBY_VERSION))
  abort("Ruby #{RUBY_VERSION} is not supported. Requires #{required_ruby_version}.")
end

# Check Bundler version
required_bundler_version = Gem::Requirement.new('>= 2.4.0')
unless required_bundler_version.satisfied_by?(Gem::Version.new(Bundler::VERSION))
  abort("Bundler #{Bundler::VERSION} is not supported. Requires #{required_bundler_version}.")
end

# Custom boot hooks (extendable)
module PixelCanvas
  class Boot
    class << self
      def run
        load_env_files
        setup_bundler
        setup_load_paths
        verify_system
      end

      private

      def load_env_files
        return unless defined?(Dotenv)
        Dotenv.load('.env', ".env.#{ENV['RAILS_ENV']}")
      end

      def setup_bundler
        require 'bundler/setup'
      end

      def setup_load_paths
        $LOAD_PATH.unshift(File.expand_path('../lib', __dir__)) unless $LOAD_PATH.include?(File.expand_path('../lib', __dir__))
      end

      def verify_system
        puts "Booting PixelCanvas Rails #{Rails.version} with Ruby #{RUBY_VERSION} and Bundler #{Bundler::VERSION}"
      end
    end
  end
end

# Run boot process
PixelCanvas::Boot.run
