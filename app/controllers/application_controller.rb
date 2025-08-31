# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks
  protect_from_forgery with: :exception

  # Use before actions for authentication and setting user context
  before_action :authenticate_user!
  before_action :set_current_user
  before_action :set_rate_limit

  # Handle common exceptions gracefully
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::RoutingError, with: :route_not_found
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from StandardError, with: :internal_server_error unless Rails.env.development?

  helper_method :current_user, :user_signed_in?, :can_draw?, :canvas_pixel_limit

  private

  ##############################
  # Authentication & User
  ##############################

  def authenticate_user!
    return if user_signed_in?

    respond_to do |format|
      format.html { redirect_to new_session_path, alert: 'You need to sign in before continuing.' }
      format.json { render json: { error: 'Unauthorized' }, status: :unauthorized }
    end
  end

  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
  end

  def current_user
    @current_user
  end

  def user_signed_in?
    current_user.present?
  end

  ##############################
  # Rate Limiting
  ##############################

  def set_rate_limit
    @rate_key = "user_rate:#{current_user&.id || 'guest'}:#{controller_name}:#{action_name}"
    @rate_limit_count = Rails.cache.read(@rate_key) || 0
  end

  def check_rate_limit(limit: 10, interval: 10.seconds)
    if @rate_limit_count >= limit
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "Rate limit exceeded. Please wait #{interval.to_i} seconds." }
        format.json { render json: { error: 'Rate limit exceeded' }, status: :too_many_requests }
      end
      return false
    else
      Rails.cache.write(@rate_key, @rate_limit_count + 1, expires_in: interval)
      true
    end
  end

  ##############################
  # Helpers for Canvas
  ##############################

  def can_draw?(pixels_required = 1)
    current_user&.available_pixels.to_i >= pixels_required
  end

  def canvas_pixel_limit
    100
  end

  ##############################
  # Error Handling
  ##############################

  def record_not_found(exception = nil)
    logger.warn "[RecordNotFound] #{exception&.message}"
    respond_to do |format|
      format.html { redirect_to root_path, alert: 'Record not found' }
      format.json { render json: { error: 'Record not found' }, status: :not_found }
    end
  end

  def route_not_found(exception = nil)
    logger.warn "[RouteNotFound] #{exception&.message}"
    respond_to do |format|
      format.html { redirect_to root_path, alert: 'Page not found' }
      format.json { render json: { error: 'Route not found' }, status: :not_found }
    end
  end

  def user_not_authorized(exception = nil)
    logger.warn "[Unauthorized] #{exception&.message}"
    respond_to do |format|
      format.html { redirect_to root_path, alert: 'You are not authorized to perform this action' }
      format.json { render json: { error: 'Forbidden' }, status: :forbidden }
    end
  end

  def internal_server_error(exception = nil)
    logger.error "[InternalServerError] #{exception&.message}\n#{exception&.backtrace&.join("\n")}"
    respond_to do |format|
      format.html { redirect_to root_path, alert: 'An unexpected error occurred. Please try again later.' }
      format.json { render json: { error: 'Internal server error' }, status: :internal_server_error }
    end
  end
end
