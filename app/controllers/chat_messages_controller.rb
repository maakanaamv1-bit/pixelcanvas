# app/controllers/chat_messages_controller.rb
class ChatMessagesController < ApplicationController
  before_action :set_chat, only: [:index, :create]
  before_action :check_rate_limit, only: [:create]
  before_action :authorize_user!, only: [:destroy]

  # GET /chat_messages?chat_id=1
  def index
    @messages = @chat.messages.includes(:user).order(created_at: :asc).limit(100)
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @messages.as_json(include: { user: { only: [:id, :username, :avatar_url] } }) }
    end
  end

  # POST /chat_messages
  def create
    @message = @chat.messages.new(message_params)
    @message.user = current_user

    if @message.save
      # Broadcast message to ActionCable channel for real-time updates
      ChatMessagesChannel.broadcast_to(@chat, {
        message: render_to_string(partial: "chat_messages/message", locals: { message: @message }),
        user_id: current_user.id,
        timestamp: @message.created_at
      })

      respond_to do |format|
        format.html { redirect_to chat_messages_path(chat_id: @chat.id), notice: 'Message sent!' }
        format.json { render json: { success: true, message: @message }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to chat_messages_path(chat_id: @chat.id), alert: @message.errors.full_messages.join(", ") }
        format.json { render json: { error: @message.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chat_messages/:id
  def destroy
    if @chat_message.destroy
      # Broadcast deletion to clients
      ChatMessagesChannel.broadcast_to(@chat_message.chat, {
        action: "destroy",
        message_id: @chat_message.id
      })
      render json: { success: true, message: "Deleted" }
    else
      render json: { error: "Unable to delete" }, status: :unprocessable_entity
    end
  end

  private

  def set_chat
    if params[:chat_id]
      @chat = Chat.find_by(id: params[:chat_id])
      render json: { error: "Chat not found" }, status: :not_found unless @chat
    else
      # Default to global chat if no chat_id provided
      @chat = Chat.global
    end
  end

  def message_params
    params.require(:chat_message).permit(:content, :chat_id)
  end

  # Rate limiting: max 5 messages per 10 seconds
  def check_rate_limit
    key = "chat_rate:#{current_user.id}"
    count = Rails.cache.read(key).to_i

    if count >= 5
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "Rate limit exceeded. Slow down!" }
        format.json { render json: { error: "Rate limit exceeded" }, status: :too_many_requests }
      end
    else
      Rails.cache.write(key, count + 1, expires_in: 10.seconds)
    end
  end

  # Ensure only owner or admin can delete
  def authorize_user!
    @chat_message = ChatMessage.find(params[:id])
    unless current_user.admin? || @chat_message.user == current_user
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end
end
