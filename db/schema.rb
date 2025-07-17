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

ActiveRecord::Schema[8.0].define(version: 2025_07_16_182828) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "airlines", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_airlines_on_name", unique: true
  end

  create_table "flight_seats", force: :cascade do |t|
    t.bigint "flight_id", null: false
    t.string "class_type", null: false
    t.integer "total_seats", null: false
    t.integer "available_seats", null: false
    t.integer "base_price", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_id"], name: "index_flight_seats_on_flight_id"
  end

  create_table "flights", force: :cascade do |t|
    t.string "flight_number", null: false
    t.bigint "airline_id", null: false
    t.string "source", null: false
    t.string "destination", null: false
    t.datetime "departure_datetime", null: false
    t.datetime "arrival_datetime", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["airline_id"], name: "index_flights_on_airline_id"
    t.index ["flight_number", "departure_datetime"], name: "index_flights_on_flight_number_and_departure_datetime"
  end

  add_foreign_key "flight_seats", "flights"
  add_foreign_key "flights", "airlines"
end
