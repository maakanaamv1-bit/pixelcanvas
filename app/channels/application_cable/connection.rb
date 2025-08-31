# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :connection_id

    # Called when a client attempts to connect
    def connect
      self.connection_id = SecureRandom.uuid
      self.current_user = find_verified_user
      logger.add_tags 'ActionCable', "User #{current_user.id}", "Conn #{connection_id}"
      logger.info "[ActionCable] Connection established for User #{current_user.id} with connection_id #{connection_id}"

      track_online_user
    end

    # Called when a client disconnects
    def disconnect
      logger.info "[ActionCable] Connection closed for User #{current_user&.id} with connection_id #{connection_id}"
      untrack_online_user
    end

    private

    # Verify user via Google OAuth session
    def find_verified_user
      # Assuming Devise + OmniAuth Google setup
      if verified_user = env['warden']&.user
        verified_user
      else
        logger.warn "[ActionCable] Unauthorized connection attempt"
        reject_unauthorized_connection
      end
    rescue => e
      logger.error "[ActionCable][Connection Error] #{e.message}\n#{e.backtrace.join("\n")}"
      reject_unauthorized_connection
    end

    # Track online user in cache for real-time presence
    def track_online_user
      return unless current_user
      key = "online_user:#{current_user.id}:connection:#{connection_id}"
      Rails.cache.write(key, true, expires_in: 15.minutes)
    end

    # Remove user from online cache
    def untrack_online_user
      return unless current_user
      key = "online_user:#{current_user.id}:connection:#{connection_id}"
      Rails.cache.delete(key)
    end

    # Rate limit connections per user (optional)
    def rate_limited?(limit: 5, interval: 1.minute)
      return false unless current_user
      key = "connection_rate_limit:#{current_user.id}"
      count = Rails.cache.read(key) || 0

      if count >= limit
        true
      else
        Rails.cache.write(key, count + 1, expires_in: interval)
        false
      end
    end
  end
end
