# app/models/chat_message.rb
class ChatMessage < ApplicationRecord
  # Soft-delete support
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  # Associations
  belongs_to :user
  belongs_to :group, optional: true # nil for global chat

  # Validations
  validates :content, presence: true, length: { maximum: 1000 }
  validates :user, presence: true

  # Callbacks
  before_create :sanitize_content
  after_create_commit :broadcast_message

  # Soft-delete a message
  def soft_delete
    update(deleted_at: Time.current)
  end

  # Restore a deleted message
  def restore
    update(deleted_at: nil)
  end

  # Helper to determine if message is global
  def global?
    group.nil?
  end

  # JSON serialization for broadcasting or API responses
  def as_json(options = {})
    super(
      options.reverse_merge(
        only: [:id, :content, :created_at],
        methods: [:user_name, :user_unique_code, :group_name]
      )
    )
  end

  def user_name
    user&.username || "Unknown"
  end

  def user_unique_code
    user&.unique_code
  end

  def group_name
    group&.name || "Global"
  end

  private

  # Prevent XSS or unsafe HTML in chat content
  def sanitize_content
    self.content = ActionController::Base.helpers.sanitize(content)
  end

  # Broadcast via ActionCable
  def broadcast_message
    channel = global? ? "GlobalChatChannel" : "GroupChatChannel_#{group.id}"
    ActionCable.server.broadcast(channel, as_json)
  end
end
