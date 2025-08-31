# app/models/group_membership.rb
class GroupMembership < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :group

  # Roles (enum)
  enum role: { member: 0, moderator: 1, admin: 2 }

  # Validations
  validates :user_id, uniqueness: { scope: :group_id, message: "is already in this group" }
  validates :role, presence: true

  # Callbacks
  before_create :set_default_role
  after_create :increment_group_member_count
  after_destroy :decrement_group_member_count

  # Scopes
  scope :admins, -> { where(role: :admin) }
  scope :moderators, -> { where(role: :moderator) }
  scope :members, -> { where(role: :member) }

  # Check if user is admin of the group
  def admin?
    role == "admin"
  end

  # Promote a member to a higher role
  def promote!
    case role
    when "member"
      update!(role: "moderator")
    when "moderator"
      update!(role: "admin")
    end
  end

  # Demote a member to a lower role
  def demote!
    case role
    when "admin"
      update!(role: "moderator")
    when "moderator"
      update!(role: "member")
    end
  end

  # JSON serialization for API
  def as_json(options = {})
    super(
      options.reverse_merge(
        only: [:id, :role],
        include: { user: { only: [:id, :username, :unique_code] } }
      )
    )
  end

  private

  def set_default_role
    self.role ||= :member
  end

  def increment_group_member_count
    group.increment!(:member_count)
  end

  def decrement_group_member_count
    group.decrement!(:member_count)
  end
end
