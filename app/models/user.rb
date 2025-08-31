# app/models/user.rb
class User < ApplicationRecord
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  # Associations
  has_many :pixels, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :color_packs, through: :purchases
  has_many :chat_messages, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships

  # Validations
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :bio, length: { maximum: 500 }
  validates :unique_code, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_unique_code, on: :create
  after_create :grant_initial_pixels_and_colors

  # Scopes
  scope :top_drawers_today, -> { joins(:pixels).where('pixels.created_at >= ?', Time.zone.now.beginning_of_day).group('users.id').order('COUNT(pixels.id) DESC') }
  scope :top_drawers_month, -> { joins(:pixels).where('pixels.created_at >= ?', Time.zone.now.beginning_of_month).group('users.id').order('COUNT(pixels.id) DESC') }
  scope :top_drawers_year, -> { joins(:pixels).where('pixels.created_at >= ?', Time.zone.now.beginning_of_year).group('users.id').order('COUNT(pixels.id) DESC') }

  # Devise Omniauth Google OAuth2 callback
  def self.from_omniauth(access_token)
    data = access_token.info
    user = User.find_or_initialize_by(email: data['email'])
    user.username ||= data['name'].parameterize(separator: '_')
    user.password ||= Devise.friendly_token[0, 20]
    user.save! if user.new_record?
    user
  end

  # Pixel and color management
  def add_pixels(count)
    self.pixel_balance += count
    save!
  end

  def remove_pixels(count)
    raise "Insufficient pixels" if pixel_balance < count
    self.pixel_balance -= count
    save!
  end

  def colors_owned_list
    color_packs.includes(:colors).map(&:colors).flatten.uniq
  end

  # Leaderboard ranking
  def leaderboard_rank(period = :all_time)
    case period
    when :today
      Pixel.where(user_id: id).where('created_at >= ?', Time.zone.now.beginning_of_day).count
    when :month
      Pixel.where(user_id: id).where('created_at >= ?', Time.zone.now.beginning_of_month).count
    when :year
      Pixel.where(user_id: id).where('created_at >= ?', Time.zone.now.beginning_of_year).count
    else
      pixels.count
    end
  end

  # Profile analytics
  def total_pixels_drawn
    pixels.count
  end

  def total_spent
    purchases.successful.sum(:amount_cents) / 100.0
  end

  # Chat helpers
  def send_global_message(content)
    ChatMessage.create!(user: self, content: content, global: true)
  end

  def send_group_message(group, content)
    raise "Not a member of group" unless groups.include?(group)
    ChatMessage.create!(user: self, content: content, group: group, global: false)
  end

  # Group management
  def create_group(name)
    groups.create!(name: name)
  end

  def join_group(group)
    groups << group unless groups.include?(group)
  end

  # Purchase helpers
  def buy_color_pack(pack)
    Purchase.create!(user: self, color_pack: pack, amount_cents: pack.price_cents, currency: 'USD', status: 'pending')
  end

  # Daily reward system
  def claim_daily_pixels
    return false if last_daily_claim && last_daily_claim > 1.day.ago
    add_pixels(10)
    update!(last_daily_claim: Time.zone.now)
  end

  # Generate unique user code
  private
  def generate_unique_code
    self.unique_code ||= loop do
      code = SecureRandom.hex(4).upcase
      break code unless User.exists?(unique_code: code)
    end
  end

  # Initial pixel and color grant
  def grant_initial_pixels_and_colors
    self.pixel_balance ||= 100
    # Assume initial 30 colors unlocked via default color pack
    default_pack = ColorPack.find_by(default: true)
    self.color_packs << default_pack if default_pack
    save!
  end
end
