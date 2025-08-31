# db/schema.rb
ActiveRecord::Schema.define(version: 2025_08_31_000006) do

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "username", null: false
    t.string "uid"              # For OAuth (Google login)
    t.string "provider"         # e.g., "google"
    t.string "encrypted_password"
    t.string "bio"
    t.integer "pixels_drawn_count", default: 0, null: false
    t.integer "play_points", default: 0, null: false
    t.timestamps
  end

  add_index "users", ["email"], unique: true
  add_index "users", ["username"], unique: true
  add_index "users", ["uid", "provider"], unique: true

  create_table "pixels", force: :cascade do |t|
    t.integer "x", null: false
    t.integer "y", null: false
    t.string "color", null: false
    t.references "user", foreign_key: true
    t.references "group", foreign_key: true
    t.timestamps
  end

  add_index "pixels", ["x", "y"], unique: true

  create_table "color_packs", force: :cascade do |t|
    t.string "name", null: false
    t.text "colors", array: true, default: []
    t.decimal "price", default: 0.0, null: false
    t.timestamps
  end

  create_table "purchases", force: :cascade do |t|
    t.references "user", null: false, foreign_key: true
    t.references "color_pack", null: false, foreign_key: true
    t.string "status", default: "pending"
    t.string "transaction_id"
    t.timestamps
  end

  create_table "chat_messages", force: :cascade do |t|
    t.references "user", null: false, foreign_key: true
    t.references "group", foreign_key: true
    t.text "content", null: false
    t.timestamps
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.references "owner", null: false, foreign_key: { to_table: :users }
    t.integer "members_count", default: 0, null: false
    t.string "status", default: "active"
    t.jsonb "settings", default: {}
    t.datetime "archived_at"
    t.datetime "banned_at"
    t.timestamps
  end

  add_index "groups", ["name"]
  add_index "groups", ["slug"], unique: true
  add_index "groups", ["status"]

  create_table "group_memberships", force: :cascade do |t|
    t.references "user", null: false, foreign_key: true
    t.references "group", null: false, foreign_key: true
    t.string "role", null: false, default: "member"
    t.string "status", null: false, default: "active"
    t.datetime "joined_at", null: false, default: -> { 'CURRENT_TIMESTAMP' }
    t.datetime "left_at"
    t.boolean "notifications_enabled", default: true
    t.jsonb "preferences", default: {}
    t.integer "pixels_drawn", default: 0
    t.integer "messages_sent", default: 0
    t.timestamps
  end

  add_index "group_memberships", ["user_id", "group_id"], unique: true
  add_index "group_memberships", ["role"]
  add_index "group_memberships", ["status"]
  add_index "group_memberships", ["joined_at"]

end
