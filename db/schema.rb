# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_08_27_165332) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "external_scores", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.integer "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_external_scores_on_player_id"
    t.index ["score", "player_id"], name: "index_external_scores_on_score_and_player_id", unique: true
  end

  create_table "games", force: :cascade do |t|
    t.string "name"
    t.string "base_uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gradual_price_scales", force: :cascade do |t|
    t.bigint "gradual_scaling_price_id", null: false
    t.decimal "point_coefficient"
    t.decimal "minimum_price"
    t.decimal "maximum_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gradual_scaling_price_id"], name: "index_gradual_price_scales_on_gradual_scaling_price_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "name"
    t.string "country"
    t.string "external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "game_id"
    t.index ["game_id"], name: "index_players_on_game_id"
  end

  create_table "price_pricing_rules", force: :cascade do |t|
    t.bigint "price_id", null: false
    t.bigint "pricing_rule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["price_id"], name: "index_price_pricing_rules_on_price_id"
    t.index ["pricing_rule_id"], name: "index_price_pricing_rules_on_pricing_rule_id"
  end

  create_table "prices", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.string "external_points"
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_prices_on_player_id"
  end

  create_table "pricing_rules", force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "name"
    t.string "external_id"
    t.string "country"
    t.bigint "game_id", null: false
    t.string "format"
    t.date "starting_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_tournaments_on_game_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "username", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "unique_usernames", unique: true
  end

  add_foreign_key "external_scores", "players"
  add_foreign_key "gradual_price_scales", "pricing_rules", column: "gradual_scaling_price_id"
  add_foreign_key "price_pricing_rules", "prices"
  add_foreign_key "price_pricing_rules", "pricing_rules"
  add_foreign_key "prices", "players"
  add_foreign_key "tournaments", "games"
end
