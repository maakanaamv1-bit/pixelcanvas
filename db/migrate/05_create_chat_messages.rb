# db/migrate/05_create_chat_messages.rb
class CreateChatMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_messages do |t|
      t.references :user, null: false, foreign_key: true           # Who sent the message
      t.references :group, null: true, foreign_key: true           # Optional group chat
      t.string :channel, null: false, default: 'global'            # 'global', 'canvas', or group channel
      t.text :content, null: false                                  # Actual message content
      t.jsonb :attachments, default: {}                             # Images, emojis, files, etc.
      t.boolean :edited, default: false                             # If message was edited
      t.datetime :edited_at                                          
      t.boolean :deleted, default: false                             # Soft deletion
      t.datetime :deleted_at                                         
      t.string :moderation_status, default: 'approved'             # 'approved', 'pending', 'flagged', 'removed'
      t.references :moderator, foreign_key: { to_table: :users }    # Moderator who acted on message
      t.text :moderation_notes                                       
      t.jsonb :metadata, default: {}                                 # Extra info (IP, user agent, embeds)
      
      t.timestamps
    end

    # Indexes for performance
    add_index :chat_messages, [:channel, :created_at]
    add_index :chat_messages, [:user_id, :created_at]
    add_index :chat_messages, [:group_id, :created_at]
    add_index :chat_messages, :moderation_status
    add_index :chat_messages, :edited
    add_index :chat_messages, :deleted
  end
end
