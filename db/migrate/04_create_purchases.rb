# db/migrate/04_create_purchases.rb
class CreatePurchases < ActiveRecord::Migration[7.1]
  def change
    create_table :purchases do |t|
      t.references :user, null: false, foreign_key: true            # Buyer
      t.references :color_pack, null: true, foreign_key: true        # Purchased pack (nullable if other items added later)
      t.decimal :amount, precision: 12, scale: 2, null: false       # Paid amount
      t.string :currency, default: 'USD', null: false               # Currency
      t.string :payment_method, null: false                         # e.g., 'stripe', 'paypal'
      t.string :status, default: 'pending', null: false             # 'pending', 'completed', 'failed', 'refunded'
      t.string :transaction_id                                       # External payment transaction id
      t.jsonb :metadata, default: {}                                 # Any extra data (receipt, coupon code, etc.)
      t.datetime :completed_at                                       # When the purchase was successfully completed
      t.datetime :refunded_at                                        # Optional refund timestamp

      # Auditing
      t.boolean :fraud_flagged, default: false
      t.text :notes

      t.timestamps
    end

    # Indexes for performance and queries
    add_index :purchases, [:user_id, :status]
    add_index :purchases, [:color_pack_id, :status]
    add_index :purchases, :transaction_id, unique: true
    add_index :purchases, :completed_at
    add_index :purchases, :refunded_at
  end
end
