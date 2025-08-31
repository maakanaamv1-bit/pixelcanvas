# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :update]

  # GET /profile
  # Show the current user's profile
  def show
    render json: profile_data(@user)
  end

  # PATCH/PUT /profile
  # Update the current user's profile (bio, avatar, etc.)
  def update
    if @user.update(profile_params)
      render json: profile_data(@user), status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /profiles/:id
  # View another user's profile
  def public_profile
    user = User.find_by(id: params[:id])
    if user
      render json: profile_data(user, public: true)
    else
      render json: { error: "User not found" }, status: :not_found
    end
  end

  private

  # Return user profile data in JSON
  def profile_data(user, public: false)
    data = {
      id: user.id,
      username: user.username,
      unique_code: user.unique_code,
      bio: user.bio,
      total_pixels_drawn: user.pixels_drawn_count,
      leaderboard_rank: user.leaderboard_rank,
      available_pixels: user.available_pixels,
      colors_owned: user.colors_owned_list,
      created_at: user.created_at
    }

    # If it's public, hide sensitive info
    if public
      data.except!(:available_pixels)
    end

    data
  end

  # Strong params for profile update
  def profile_params
    params.require(:user).permit(:bio, :avatar_url)
  end

  def set_user
    @user = current_user
  end
end
