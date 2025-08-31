# db/migrate/03_create_color_packs.rb
class CreateColorPacks < ActiveRecord::Migration[7.1]
  def change
    create_table :color_packs do |t|
      t.string :name, null: false                     # Name of the pack
      t.text :description                             # Description / lore
      t.jsonb :colors, null: false, default: []      # Array of HEX colors
      t.decimal :price, precision: 10, scale: 2, default: 0.0 # Price if purchasable
      t.boolean :free, default: true                  # Free packs
      t.integer :unlock_level, default: 0            # Level required to unlock
      t.references :creator, foreign_key: { to_table: :users }, null: true # Optional user creator

      # For tracking usage statistics
      t.integer :times_used, default: 0
      t.integer :unique_users, default: 0

      # Optional tags for filtering in the shop
      t.string :tags, array: true, default: []

      # Auditing / moderation
      t.boolean :approved, default: true
      t.text :moderation_notes

      t.timestamps
    end

    # Indexes for performance
    add_index :color_packs, :name, unique: true
    add_index :color_packs, :free
    add_index :color_packs, :unlock_level
    add_index :color_packs, :tags, using: 'gin'
    add_index :color_packs, :creator_id
  end
end
