# app/channels/application_cable/channel.rb
module ApplicationCable
  class Channel < ActionCable::Channel::Base
    # Called when a client subscribes
    def subscribed
      Rails.logger.info "[ActionCable][#{self.class.name}] User #{current_user&.id || 'Guest'} subscribed"
      
      unless authorized?
        reject
        Rails.logger.warn "[ActionCable][#{self.class.name}] Unauthorized subscription attempt"
        return
      end

      track_subscription
      broadcast_presence(:joined)
    end

    # Called when a client unsubscribes
    def unsubscribed
      Rails.logger.info "[ActionCable][#{self.class.name}] User #{current_user&.id || 'Guest'} unsubscribed"
      untrack_subscription
      broadcast_presence(:left)
    end

    private

    # Returns the currently connected user (from connection)
    def current_user
      connection.current_user
    rescue
      nil
    end

    # Check if user is authorized to subscribe to this channel
    def authorized?
      current_user.present?
    end

    # Rate limit messages/actions per user
    # Example: max 30 actions per 10 seconds
    def rate_limited?(limit: 30, interval: 10.seconds)
      return false unless current_user

      key = "rate_limit:#{current_user.id}:#{self.class.name}"
      count = Rails.cache.read(key) || 0

      if count >= limit
        true
      else
        Rails.cache.write(key, count + 1, expires_in: interval)
        false
      end
    end

    # Track user presence online in cache
    def track_subscription
      return unless current_user
      key = "online_user:#{current_user.id}:#{self.class.name}"
      Rails.cache.write(key, true, expires_in: 15.minutes)
    end

    # Remove user from online cache
    def untrack_subscription
      return unless current_user
      key = "online_user:#{current_user.id}:#{self.class.name}"
      Rails.cache.delete(key)
    end

    # Broadcast a safe message to a stream
    def safe_broadcast(stream_name, payload)
      ActionCable.server.broadcast(stream_name, payload)
    rescue => e
      Rails.logger.error "[ActionCable][Broadcast Error] #{e.message}\n#{e.backtrace.join("\n")}"
    end

    # Broadcast presence updates (joined/left) for analytics or user list
    def broadcast_presence(action)
      return unless current_user
      stream_name = "presence:#{self.class.name}"
      safe_broadcast(stream_name, {
        user_id: current_user.id,
        username: current_user.username,
        action: action,
        timestamp: Time.current.to_i
      })
    end

    # Catch all exceptions in channel actions
    rescue_from(StandardError) do |exception|
      Rails.logger.error "[ActionCable][#{self.class.name}] Error: #{exception.message}\n#{exception.backtrace.join("\n")}"
      transmit({ error: "An unexpected error occurred: #{exception.message}" })
    end
  end
end
