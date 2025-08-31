# app/models/purchase.rb
class Purchase < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :color_pack, optional: true

  # Validations
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD EUR GBP] }
  validates :status, presence: true, inclusion: { in: %w[pending completed failed refunded] }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: 'completed') }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  # Callbacks
  after_create :initiate_stripe_payment
  after_update :process_successful_payment, if: -> { saved_change_to_status? && status == 'completed' }
  after_update :notify_user_payment_status_change, if: -> { saved_change_to_status? }

  # Stripe Integration
  def initiate_stripe_payment
    return if self.amount_cents.zero?

    begin
      session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        line_items: [{
          price_data: {
            currency: currency,
            product_data: { name: purchase_description },
            unit_amount: amount_cents
          },
          quantity: 1
        }],
        mode: 'payment',
        success_url: Rails.application.routes.url_helpers.root_url + "?purchase_success=true",
        cancel_url: Rails.application.routes.url_helpers.root_url + "?purchase_cancel=true",
        metadata: { purchase_id: id }
      )
      update!(stripe_session_id: session.id)
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error: #{e.message}"
      update!(status: 'failed')
    end
  end

  # Grant purchased items after successful payment
  def process_successful_payment
    ActiveRecord::Base.transaction do
      if color_pack.present?
        user.color_packs << color_pack unless user.color_packs.include?(color_pack)
      else
        # Example: Pixel bundle (add virtual pixels to user balance)
        user.increment!(:pixel_balance, pixel_quantity)
      end
      log_purchase
    end
  end

  # Helper to describe the purchase
  def purchase_description
    if color_pack.present?
      "Color Pack: #{color_pack.name}"
    else
      "#{pixel_quantity} Pixel#{'s' if pixel_quantity > 1} Bundle"
    end
  end

  # Notify user of status changes
  def notify_user_payment_status_change
    UserMailer.with(user: user, purchase: self).purchase_status_email.deliver_later
  end

  # Log analytics or audit
  def log_purchase
    Rails.logger.info "Purchase completed: #{id} by user #{user.id}"
    Analytics.track(
      user_id: user.id,
      event: 'purchase_completed',
      properties: {
        amount: amount_cents,
        currency: currency,
        color_pack: color_pack&.name,
        pixels: pixel_quantity
      }
    )
  end

  # Virtual attribute for pixel quantity if buying pixels instead of packs
  def pixel_quantity
    self[:pixel_quantity] || 0
  end

  # Status helpers
  def completed?; status == 'completed'; end
  def pending?; status == 'pending'; end
  def failed?; status == 'failed'; end
  def refunded?; status == 'refunded'; end

  # Class methods for analytics
  def self.total_revenue
    successful.sum(:amount_cents) / 100.0
  end

  def self.top_buyers(limit = 10)
    select('user_id, SUM(amount_cents) as total_spent')
      .where(status: 'completed')
      .group(:user_id)
      .order('total_spent DESC')
      .limit(limit)
  end
end
