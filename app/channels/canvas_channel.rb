# app/channels/canvas_channel.rb
class CanvasChannel < ApplicationCable::Channel
  # Called when the client subscribes
  def subscribed
    reject unless current_user
    stream_for :canvas
    logger.info "[CanvasChannel] User #{current_user.id} subscribed"
    
    # Optionally send initial canvas state
    transmit_initial_canvas_state
  end

  # Called when the client unsubscribes
  def unsubscribed
    logger.info "[CanvasChannel] User #{current_user.id} unsubscribed"
  end

  # Draw a pixel
  def draw_pixel(data)
    return unless current_user
    return if rate_limited?

    x = data['x'].to_i
    y = data['y'].to_i
    color = sanitize_color(data['color'])

    return unless valid_pixel?(x, y, color)

    pixel = Pixel.find_or_initialize_by(x: x, y: y)
    pixel.user = current_user
    pixel.color = color
    pixel.drawn_at = Time.current

    if pixel.save
      increment_user_pixel_count(current_user)
      broadcast_pixel(pixel)
    else
      logger.error "[CanvasChannel] Failed to save pixel: #{pixel.errors.full_messages.join(', ')}"
    end
  rescue => e
    logger.error "[CanvasChannel][draw_pixel error] #{e.message}\n#{e.backtrace.join("\n")}"
  end

  private

  # Broadcast the pixel to all subscribed clients
  def broadcast_pixel(pixel)
    CanvasChannel.broadcast_to(:canvas, {
      x: pixel.x,
      y: pixel.y,
      color: pixel.color,
      user_id: pixel.user.id,
      timestamp: pixel.drawn_at.to_i
    })
  end

  # Send the initial canvas state when a user connects
  def transmit_initial_canvas_state
    pixels = Pixel.all.limit(10000).map do |p|
      { x: p.x, y: p.y, color: p.color, user_id: p.user.id }
    end
    transmit(action: 'initial_canvas', pixels: pixels)
  end

  # Validate coordinates and color
  def valid_pixel?(x, y, color)
    return false unless x.between?(0, 99) && y.between?(0, 99)
    return false unless color.match?(/\A#[0-9a-fA-F]{6}\z/)
    true
  end

  # Sanitize color input
  def sanitize_color(color)
    color = color.to_s.strip
    color.start_with?('#') ? color[0..6] : "##{color[0..5]}"
  end

  # Simple rate limiter per user
  def rate_limited?(limit: 1, interval: 10.seconds)
    key = "pixel_draw_rate:#{current_user.id}"
    count = Rails.cache.read(key) || 0

    if count >= limit
      transmit(action: 'rate_limited', message: "Wait #{interval.to_i} seconds before drawing again")
      true
    else
      Rails.cache.write(key, count + 1, expires_in: interval)
      false
    end
  end

  # Increment the user's drawn pixel counters
  def increment_user_pixel_count(user)
    user.increment!(:pixels_drawn_all_time)
    user.increment!(:pixels_drawn_today)
    # Optional: increment month/year counters if stored separately
  end
end
