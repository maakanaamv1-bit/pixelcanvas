# frozen_string_literal: true
# =============================================================================
# PixelCanvas Boot Script
# Handles Bundler, multiple platforms, and Rails safe loading
# =============================================================================

require "fileutils"
require "rbconfig"
require "bundler"

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

module PixelCanvas
  class Boot
    class << self
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

      def setup_bundler
        Bundler.setup(:default, ENV["RAILS_ENV"] || "development")
        Bundler.require(*Bundler.groups)
      rescue Bundler::BundlerError => e
        warn "[Boot] Bundler setup failed: #{e.message}"
        exit 1
      end

      def load_rails
        require "rails"
        require "rails/all"
      rescue LoadError => e
        warn "[Boot] Rails not loaded: #{e.message}"
        exit 1
      end

      def log_boot
        puts "[Boot] PixelCanvas booting on Ruby #{RUBY_VERSION}, Bundler #{Bundler::VERSION}, platform #{RUBY_PLATFORM}"
      end

      def run
        ensure_platform_compatibility
        setup_bundler
        log_boot
        load_rails
      end
    end
  end
end

PixelCanvas::Boot.run

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
