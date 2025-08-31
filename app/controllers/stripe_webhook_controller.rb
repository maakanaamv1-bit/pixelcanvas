class StripeWebhookController < ApplicationController
  # Disable CSRF for webhook endpoint
  protect_from_forgery except: :receive
  before_action :verify_stripe_signature!

  # POST /stripe_webhook
  def receive
    event = nil

    begin
      payload = request.body.read
      sig_header = request.env['HTTP_STRIPE_SIGNATURE']
      endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      render json: { error: "Invalid payload" }, status: 400 and return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: "Invalid signature" }, status: 400 and return
    end

    case event.type
    when 'checkout.session.completed'
      handle_checkout_session_completed(event.data.object)
    when 'invoice.payment_succeeded'
      handle_invoice_payment_succeeded(event.data.object)
    when 'invoice.payment_failed'
      handle_invoice_payment_failed(event.data.object)
    else
      Rails.logger.info("Unhandled event type: #{event.type}")
    end

    render json: { status: 'success' }
  end

  private

  def handle_checkout_session_completed(session)
    user = User.find_by(id: session.client_reference_id)
    return unless user

    # Handle one-time purchases
    if session.payment_status == 'paid'
      # Determine product purchased
      product_id = session.metadata['product_id']
      case product_id
      when 'pixel_pack_100'
        user.increment!(:pixel_count, 100)
      when 'color_pack_60'
        user.color_packs << ColorPack.find_by(name: '60 Colors')
      when 'color_pack_120'
        user.color_packs << ColorPack.find_by(name: '120 Colors')
      end
      Rails.logger.info("Checkout session completed for User #{user.id}")
    end
  end

  def handle_invoice_payment_succeeded(invoice)
    subscription_id = invoice.subscription
    stripe_subscription = Stripe::Subscription.retrieve(subscription_id)
    user = User.find_by(stripe_customer_id: invoice.customer)
    return unless user

    # Mark subscription as active
    user.update(subscription_status: 'active', subscription_plan: stripe_subscription.items.data[0].price.id)
    Rails.logger.info("Invoice payment succeeded for User #{user.id}")
  end

  def handle_invoice_payment_failed(invoice)
    user = User.find_by(stripe_customer_id: invoice.customer)
    return unless user

    # Mark subscription as inactive
    user.update(subscription_status: 'past_due')
    Rails.logger.warn("Invoice payment failed for User #{user.id}")
  end

  def verify_stripe_signature!
    unless Rails.application.credentials.dig(:stripe, :webhook_secret).present?
      raise "Stripe webhook secret missing in credentials"
    end
  end
end
