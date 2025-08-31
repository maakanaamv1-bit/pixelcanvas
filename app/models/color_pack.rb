# app/models/color_pack.rb
class ColorPack < ApplicationRecord
  # Associations
  has_many :purchases, dependent: :destroy
  has_many :users, through: :purchases

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :colors, presence: true
  validate :colors_format

  # Serialize colors as an array
  serialize :colors, Array

  # Scopes
  scope :free, -> { where(price_cents: 0) }
  scope :paid, -> { where("price_cents > 0") }

  # Returns true if user has unlocked this pack
  def unlocked_by?(user)
    return false unless user
    user.color_packs.include?(self)
  end

  # Unlocks this pack for a user via purchase
  def unlock_for(user)
    return if unlocked_by?(user)
    purchases.create!(user: user, purchased_at: Time.current, price_cents: price_cents)
  end

  # Total number of users who unlocked this pack
  def unlocked_count
    users.count
  end

  # Format colors to ensure valid hex codes
  def colors_format
    unless colors.all? { |c| c =~ /^#(?:[0-9a-fA-F]{3}){1,2}$/ }
      errors.add(:colors, "must be valid hex color codes")
    end
  end

  # JSON serialization for front-end
  def as_json(options = {})
    super(
      options.reverse_merge(
        only: [:id, :name, :price_cents],
        methods: [:colors, :unlocked_count]
      )
    )
  end
end
