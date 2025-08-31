# db/migrate/01_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      # Basic authentication & OAuth
      t.string :provider, null: false, default: "google"
      t.string :uid, null: false
      t.string :email, null: false, index: { unique: true }
      t.string :encrypted_password
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      # Profile info
      t.string :username, null: false, index: { unique: true }
      t.text :bio
      t.string :avatar_url
      t.string :unique_code, null: false, index: { unique: true }

      # Pixel drawing stats
      t.integer :pixels_drawn_today, default: 0
      t.integer :pixels_drawn_month, default: 0
      t.integer :pixels_drawn_year, default: 0
      t.integer :pixels_drawn_all_time, default: 0

      # Colors & packs
      t.jsonb :colors_unlocked, default: []
      t.integer :color_pack_level, default: 0 # free / paid tiers

      # Game economy
      t.integer :play_points, default: 0
      t.integer :extra_pixels, default: 0

      # Stripe / payment info
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.datetime :subscription_expires_at
      t.boolean :subscribed, default: false

      # Misc / timestamps
      t.timestamps
    end

    add_index :users, [:provider, :uid], unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
