# config/initializers/stripe.rb

require 'stripe'

Rails.configuration.stripe = {
  publishable_key: ENV.fetch('STRIPE_PUBLISHABLE_KEY'),
  secret_key: ENV.fetch('STRIPE_SECRET_KEY'),
  webhook_secret: ENV.fetch('STRIPE_WEBHOOK_SECRET') # used for verifying webhooks
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]

# Optional: Set default Stripe API version
Stripe.api_version = '2025-08-01'

# Log all Stripe requests for debugging (optional)
Stripe.log_level = Rails.env.development? ? :debug : :info

# Module to handle Stripe Webhooks safely
module StripeWebhookHandler
  extend self

  # Verify webhook signature and parse event
  def construct_event(payload, sig_header)
    secret = Rails.configuration.stripe[:webhook_secret]
    begin
      Stripe::Webhook.construct_event(payload, sig_header, secret)
    rescue JSON::ParserError => e
      Rails.logger.error("[Stripe Webhook] Invalid payload: #{e.message}")
      raise
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error("[Stripe Webhook] Invalid signature: #{e.message}")
      raise
    end
  end

  # Example: handle successful payment intents
  def handle_event(event)
    case event.type
    when 'payment_intent.succeeded'
      payment_intent = event.data.object
      Rails.logger.info("[Stripe] Payment succeeded: #{payment_intent.id} for amount #{payment_intent.amount}")
      # TODO: update user purchase records, grant color packs or pixel points
    when 'checkout.session.completed'
      session = event.data.object
      Rails.logger.info("[Stripe] Checkout session completed: #{session.id}")
      # TODO: fulfill order, grant digital goods, etc.
    when 'customer.subscription.created'
      subscription = event.data.object
      Rails.logger.info("[Stripe] New subscription created: #{subscription.id}")
      # TODO: activate subscription-based color access
    else
      Rails.logger.info("[Stripe] Unhandled event type: #{event.type}")
    end
  end
end

# Optional: Automatically create test products and plans if in development
if Rails.env.development?
  Rails.logger.info("[Stripe] Development mode: creating example products and plans")
  # Uncomment and customize as needed:
  # product = Stripe::Product.create(name: 'PixelCanvas Color Pack')
  # plan = Stripe::Price.create(unit_amount: 500, currency: 'usd', recurring: {interval: 'month'}, product: product.id)
end
