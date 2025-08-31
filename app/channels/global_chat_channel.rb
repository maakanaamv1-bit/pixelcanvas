# app/channels/global_chat_channel.rb
class GlobalChatChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user
    stream_for :global_chat
    logger.info "[GlobalChat] User #{current_user.id} joined global chat"
    
    # Optionally send last 50 messages on subscribe
    transmit_recent_messages
  end

  def unsubscribed
    logger.info "[GlobalChat] User #{current_user.id} left global chat"
  end

  # Receive a chat message
  def send_message(data)
    return unless current_user
    return if rate_limited?

    content = sanitize_message(data['content'])
    return if content.blank?

    message = ChatMessage.create!(
      user: current_user,
      content: content,
      chat_type: 'global'
    )

    GlobalChatChannel.broadcast_to(:global_chat, {
      user_id: current_user.id,
      username: current_user.username,
      content: message.content,
      timestamp: message.created_at.to_i
    })
  rescue => e
    logger.error "[GlobalChat][send_message error] #{e.message}\n#{e.backtrace.join("\n")}"
  end

  private

  def transmit_recent_messages
    messages = ChatMessage.where(chat_type: 'global').order(created_at: :desc).limit(50).reverse
    transmit(action: 'recent_messages', messages: messages.map { |m|
      {
        user_id: m.user.id,
        username: m.user.username,
        content: m.content,
        timestamp: m.created_at.to_i
      }
    })
  end

  def sanitize_message(content)
    ActionController::Base.helpers.sanitize(content.to_s.strip)
  end

  def rate_limited?(limit: 1, interval: 5.seconds)
    key = "global_chat_rate:#{current_user.id}"
    count = Rails.cache.read(key) || 0

    if count >= limit
      transmit(action: 'rate_limited', message: "Wait #{interval.to_i} seconds before sending another message")
      true
    else
      Rails.cache.write(key, count + 1, expires_in: interval)
      false
    end
  end
end
