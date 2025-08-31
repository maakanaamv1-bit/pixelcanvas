# frozen_string_literal: true

# =============================================================================
# PixelCanvas Boot Script
# Purpose: Robust bootloader for Rails 8 apps on multiple platforms
# Author: Generated for Heroku deployment
# =============================================================================

require "fileutils"
require "rbconfig"
require "bundler"

# -----------------------------
# Set Gemfile environment
# -----------------------------
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# -----------------------------
# Helper module for boot tasks
# -----------------------------
module PixelCanvas
  class Boot
    class << self
      # Detect platform and adjust Bundler lockfile if needed
      def ensure_platform_compatibility
        return unless Bundler.default_lockfile.exist?

        Bundler.locked_gems.specs.each do |spec|
          if spec.platform.to_s == "x64-mingw-ucrt" && RUBY_PLATFORM =~ /linux/
            puts "[Boot] Adding Linux platform for #{spec.name}"
            Bundler.lock.add_platform("x86_64-linux")
          end
        end
      rescue StandardError => e
        warn "[Boot] Platform adjustment skipped: #{e.message}"
      end

      # Initialize Bundler and require gems
      def setup_bundler
        Bundler.setup(:default, ENV["RAILS_ENV"] || "development")
        Bundler.require(*Bundler.groups)
      rescue Bundler::BundlerError => e
        warn "[Boot] Bundler setup failed: #{e.message}"
        exit 1
      end

      # Load Rails safely
      def load_rails
        require "rails"
        require "rails/all"
      rescue LoadError => e
        warn "[Boot] Rails not loaded: #{e.message}"
        exit 1
      end

      # Logging utility
      def log_boot
        ruby_ver = RUBY_VERSION
        bundler_ver = Bundler::VERSION
        platform   = RUBY_PLATFORM
        puts "[Boot] PixelCanvas booting on Ruby #{ruby_ver} with Bundler #{bundler_ver} (#{platform})"
      end

      # Run the boot process
      def run
        ensure_platform_compatibility
        setup_bundler
        log_boot
        load_rails
      end
    end
  end
end

# -----------------------------
# Execute boot
# -----------------------------
PixelCanvas::Boot.run

# -----------------------------
# Add app lib folder to load path
# -----------------------------
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
