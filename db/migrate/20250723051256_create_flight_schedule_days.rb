class CreateFlightScheduleDays < ActiveRecord::Migration[7.0]
  def change
    create_table :flight_schedule_days do |t|
      t.references :flight_schedule, null: false, foreign_key: true
      t.integer :day_of_week, null: false

      t.timestamps
    end

    add_index :flight_schedule_days, [ :flight_schedule_id, :day_of_week ], unique: true, name: "index_schedule_days_on_schedule_id_and_day"
  end
end
