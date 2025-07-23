class CreateFlightSchedules < ActiveRecord::Migration[7.0]
  def change
    create_table :flight_schedules do |t|
      t.references :flight, null: false, foreign_key: true
      t.time :departure_time, null: false
      t.time :arrival_time, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.boolean :recurring, default: false, null: false

      t.timestamps
    end
    add_index :flight_schedules,
      [ :flight_id, :departure_time, :arrival_time, :start_date, :end_date ],
      unique: true,
      name: "index_unique_flight_schedule_combo"
  end
end
