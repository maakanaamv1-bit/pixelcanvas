class SessionsController < ApplicationController
  # Skip authentication for login/logout actions
  skip_before_action :authenticate_user!, only: [:new, :create, :omniauth]

  # Render login page
  def new
    redirect_to root_path if user_signed_in?
  end

  # Standard email/password login
  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user&.valid_password?(params[:password])
      sign_in(user)
      flash[:notice] = "Signed in successfully!"
      redirect_to root_path
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  # Logout
  def destroy
    if user_signed_in?
      sign_out(current_user)
      flash[:notice] = "Signed out successfully!"
    end
    redirect_to root_path
  end

  # Google OAuth callback
  def omniauth
    auth = request.env['omniauth.auth']

    # Find or create user from Google OAuth data
    user = User.where(provider: auth.provider, uid: auth.uid).first_or_initialize do |u|
      u.email = auth.info.email
      u.name = auth.info.name
      u.password = Devise.friendly_token[0, 20]
      u.avatar_url = auth.info.image
    end

    if user.save
      sign_in(user)
      flash[:notice] = "Signed in with Google successfully!"
      redirect_to root_path
    else
      flash[:alert] = "Error signing in with Google: #{user.errors.full_messages.join(', ')}"
      redirect_to new_session_path
    end
  end

  # Optional JSON login (for AJAX)
  def api_login
    user = User.find_by(email: params[:email]&.downcase)

    if user&.valid_password?(params[:password])
      sign_in(user)
      render json: { success: true, user: user.as_json(only: [:id, :name, :email]) }
    else
      render json: { success: false, error: "Invalid email or password" }, status: :unauthorized
    end
  end

  private

  # Devise authentication helpers
  def sign_in(user)
    session[:user_id] = user.id
  end

  def sign_out(_user)
    session.delete(:user_id)
  end

  def user_signed_in?
    session[:user_id].present?
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
end
