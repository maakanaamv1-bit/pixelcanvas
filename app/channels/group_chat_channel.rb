# app/channels/group_chat_channel.rb
class GroupChatChannel < ApplicationCable::Channel
  def subscribed
    group = Group.find_by(id: params[:group_id])
    unless group && group.members.include?(current_user)
      reject
      return
    end

    @group = group
    stream_for group
    logger.info "[GroupChat] User #{current_user.id} joined group #{@group.id}"

    transmit_recent_group_messages
  end

  def unsubscribed
    logger.info "[GroupChat] User #{current_user.id} left group #{@group.id}" if @group
  end

  # Send a message to the group
  def send_message(data)
    return unless current_user && @group
    return unless @group.members.include?(current_user)
    return if rate_limited?

    content = sanitize_message(data['content'])
    return if content.blank?

    message = ChatMessage.create!(
      user: current_user,
      content: content,
      chat_type: 'group',
      group: @group
    )

    GroupChatChannel.broadcast_to(@group, {
      user_id: current_user.id,
      username: current_user.username,
      content: message.content,
      timestamp: message.created_at.to_i
    })
  rescue => e
    logger.error "[GroupChat][send_message error] #{e.message}\n#{e.backtrace.join("\n")}"
  end

  private

  def transmit_recent_group_messages
    messages = @group.chat_messages.order(created_at: :desc).limit(50).reverse
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
    key = "group_chat_rate:#{current_user.id}:#{@group.id}"
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
