# app/models/group.rb
class Group < ApplicationRecord
  # Associations
  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :chat_messages, as: :chatable, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }
  validates :description, length: { maximum: 500 }

  # Callbacks
  before_create :set_default_member_count
  before_save :normalize_name

  # Scopes
  scope :popular, -> { order(member_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  # Group ownership
  def owner
    group_memberships.find_by(role: :admin)&.user
  end

  # Add a user to group with optional role
  def add_user(user, role = :member)
    membership = group_memberships.find_or_initialize_by(user: user)
    membership.role = role
    membership.save!
    membership
  end

  # Remove a user from group
  def remove_user(user)
    membership = group_memberships.find_by(user: user)
    membership&.destroy
  end

  # Check if a user is part of the group
  def member?(user)
    users.exists?(user.id)
  end

  # Check if a user is admin of the group
  def admin?(user)
    group_memberships.find_by(user: user)&.admin?
  end

  # Broadcast chat message to group's ActionCable channel
  def broadcast_message(message)
    ChatMessagesChannel.broadcast_to(self, message: message.as_json)
  end

  # Total pixels drawn by all group members
  def total_pixels_drawn
    Pixel.where(user_id: users.pluck(:id)).count
  end

  # JSON serialization for API
  def as_json(options = {})
    super(
      options.reverse_merge(
        only: [:id, :name, :description, :member_count],
        include: {
          users: { only: [:id, :username, :unique_code] },
          group_memberships: { only: [:id, :role], include: { user: { only: [:id, :username] } } }
        }
      )
    )
  end

  private

  def set_default_member_count
    self.member_count ||= 0
  end

  def normalize_name
    self.name = name.strip.titleize
  end
end
