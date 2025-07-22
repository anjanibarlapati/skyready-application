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

ActiveRecord::Schema[8.0].define(version: 2025_07_22_053305) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "airlines", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_airlines_on_name", unique: true
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "flight_schedule_id", null: false
    t.date "flight_date", null: false
    t.string "class_type", null: false
    t.integer "available_seats", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_schedule_id"], name: "index_bookings_on_flight_schedule_id"
  end

  create_table "flight_routes", force: :cascade do |t|
    t.string "flight_number", null: false
    t.string "airline_name", null: false
    t.string "source", null: false
    t.string "destination", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "flight_schedules", force: :cascade do |t|
    t.bigint "flight_route_id", null: false
    t.time "departure_time", null: false
    t.time "arrival_time", null: false
    t.integer "days_of_week", null: false, array: true
    t.date "start_date", null: false
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "recurring", default: false, null: false
    t.index ["flight_route_id"], name: "index_flight_schedules_on_flight_route_id"
  end

  create_table "flight_seats", force: :cascade do |t|
    t.bigint "flight_schedule_id", null: false
    t.string "class_type", null: false
    t.integer "total_seats", null: false
    t.integer "base_price", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_schedule_id"], name: "index_flight_seats_on_flight_schedule_id"
  end

  add_foreign_key "bookings", "flight_schedules"
  add_foreign_key "flight_routes", "airlines", column: "airline_name", primary_key: "name"
  add_foreign_key "flight_schedules", "flight_routes"
  add_foreign_key "flight_seats", "flight_schedules"
end
