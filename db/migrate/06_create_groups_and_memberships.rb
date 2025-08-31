# db/migrate/06_create_groups_and_memberships.rb
class CreateGroupsAndMemberships < ActiveRecord::Migration[7.1]
  def change
    # Create groups table
    create_table :groups do |t|
      t.string :name, null: false, unique: true                     # Group name
      t.string :slug, null: false, unique: true                     # URL-friendly identifier
      t.text :description                                             
      t.references :owner, null: false, foreign_key: { to_table: :users } # Owner of the group
      t.integer :members_count, default: 0, null: false             # Counter cache
      t.string :status, default: 'active'                            # active, archived, banned
      t.jsonb :settings, default: {}                                  # Custom settings (e.g., color palette, chat permissions)
      t.datetime :archived_at
      t.datetime :banned_at
      t.timestamps
    end

    add_index :groups, :name
    add_index :groups, :slug, unique: true
    add_index :groups, :status

    # Create group memberships table
    create_table :group_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.string :role, null: false, default: 'member'                 # member, admin, moderator
      t.string :status, null: false, default: 'active'              # active, pending, banned, left
      t.datetime :joined_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :left_at
      t.boolean :notifications_enabled, default: true               # Group notifications
      t.jsonb :preferences, default: {}                               # Custom preferences for this user in this group
      t.integer :pixels_drawn, default: 0                             # Tracks user activity in this group
      t.integer :messages_sent, default: 0                             # Tracks user chat activity
      t.timestamps
    end

    # Unique membership per user per group
    add_index :group_memberships, [:user_id, :group_id], unique: true
    add_index :group_memberships, :role
    add_index :group_memberships, :status
    add_index :group_memberships, :joined_at
  end
end
