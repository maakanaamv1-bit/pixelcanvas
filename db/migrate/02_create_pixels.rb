# db/migrate/02_create_pixels.rb
class CreatePixels < ActiveRecord::Migration[7.1]
  def change
    create_table :pixels do |t|
      # Pixel location and color
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :color, null: false

      # Who drew it
      t.references :user, null: false, foreign_key: true, index: true

      # Time information
      t.datetime :drawn_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      # Optional grouping / layers
      t.references :group, foreign_key: true, null: true
      t.integer :layer, default: 0

      # Pixel effects (future extensions)
      t.boolean :animated, default: false
      t.jsonb :effects, default: {}

      # Pixel history / moderation
      t.boolean :flagged, default: false
      t.text :moderation_notes

      t.timestamps
    end

    # Composite index for fast lookup
    add_index :pixels, [:x, :y], unique: true
    add_index :pixels, [:user_id, :drawn_at]
    add_index :pixels, [:group_id, :layer]
  end
end
