# app/controllers/pixels_controller.rb
class PixelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pixel, only: [:update, :show]
  before_action :check_cooldown, only: [:create, :update]

  # GET /pixels
  # Fetches current pixel state for the canvas
  def index
    # Returns all pixels as JSON for frontend rendering
    @pixels = Pixel.all
    render json: @pixels.as_json(only: [:x, :y, :color, :user_id])
  end

  # POST /pixels
  # Place a new pixel on the canvas
  def create
    color = params[:color] || current_user.default_color
    x = params[:x]
    y = params[:y]

    # Check if user has enough pixels to place
    if current_user.available_pixels <= 0
      render json: { error: "No available pixels. Buy more or wait for refill." }, status: :forbidden
      return
    end

    # Check color ownership
    unless current_user.can_use_color?(color)
      render json: { error: "You cannot use this color. Unlock it first." }, status: :forbidden
      return
    end

    @pixel = Pixel.find_or_initialize_by(x: x, y: y)
    @pixel.user = current_user
    @pixel.color = color

    if @pixel.save
      current_user.decrement!(:available_pixels)
      current_user.increment!(:pixels_drawn_count)
      
      # Broadcast to canvas channel in real-time
      ActionCable.server.broadcast("canvas_channel", pixel: @pixel.as_json(only: [:x, :y, :color, :user_id]))

      render json: @pixel, status: :created
    else
      render json: { errors: @pixel.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /pixels/:id
  # Update an existing pixel (like overwriting)
  def update
    color = params[:color] || @pixel.color

    unless current_user.can_use_color?(color)
      render json: { error: "You cannot use this color." }, status: :forbidden
      return
    end

    @pixel.user = current_user
    @pixel.color = color

    if @pixel.save
      ActionCable.server.broadcast("canvas_channel", pixel: @pixel.as_json(only: [:x, :y, :color, :user_id]))
      render json: @pixel
    else
      render json: { errors: @pixel.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /pixels/:id
  def show
    render json: @pixel.as_json(only: [:x, :y, :color, :user_id])
  end

  private

  def set_pixel
    @pixel = Pixel.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Pixel not found." }, status: :not_found
  end

  # Cooldown check: 10 seconds per pixel
  def check_cooldown
    last_pixel_time = current_user.last_pixel_at || 10.years.ago
    if last_pixel_time > 10.seconds.ago
      wait_time = (10 - (Time.current - last_pixel_time)).ceil
      render json: { error: "Cooldown active. Wait #{wait_time} seconds." }, status: :forbidden
      return
    end
    current_user.update!(last_pixel_at: Time.current)
  end
end
