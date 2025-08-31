# app/models/pixel.rb
class Pixel < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :color_pack, optional: true

  # Validations
  validates :x, :y, :color, presence: true
  validates :x, :y, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :color, format: { with: /\A#?(?:[A-F0-9]{3}){1,2}\z/i, message: "must be a valid hex color" }

  # Scopes
  scope :recent, -> { order(updated_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_color, ->(color) { where(color: color) }

  # Callbacks
  after_create_commit :broadcast_pixel
  after_create :increment_user_pixel_count
  after_destroy :decrement_user_pixel_count

  # Real-time broadcasting to canvas
  def broadcast_pixel
    CanvasChannel.broadcast_to('global_canvas', {
      id: id,
      x: x,
      y: y,
      color: color,
      user_id: user_id,
      created_at: created_at
    })
  end

  # Pixel ownership and user analytics
  def increment_user_pixel_count
    user.increment!(:pixels_drawn_count)
    user.update_last_pixel_drawn_at
  end

  def decrement_user_pixel_count
    user.decrement!(:pixels_drawn_count)
  end

  # Determine if a pixel can be modified by a given user
  def editable_by?(user)
    self.user_id == user.id || user.admin?
  end

  # Apply color pack to pixel if unlocked
  def apply_color_pack!(pack)
    if user.color_packs.include?(pack)
      update!(color: pack.default_color)
    else
      raise "User does not own this color pack"
    end
  end

  # JSON representation for frontend canvas updates
  def as_json(options = {})
    super(
      options.reverse_merge(
        only: [:id, :x, :y, :color, :user_id],
        methods: [:user_name, :color_pack_name]
      )
    )
  end

  # Helper methods
  def user_name
    user.username
  end

  def color_pack_name
    color_pack&.name
  end

  # Class methods for analytics
  def self.pixels_drawn_today
    where('created_at >= ?', Time.zone.now.beginning_of_day).count
  end

  def self.pixels_drawn_this_month
    where('created_at >= ?', Time.zone.now.beginning_of_month).count
  end

  def self.pixels_drawn_this_year
    where('created_at >= ?', Time.zone.now.beginning_of_year).count
  end
end
