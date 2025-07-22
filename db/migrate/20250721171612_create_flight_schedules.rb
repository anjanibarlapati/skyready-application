class CreateFlightSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :flight_schedules do |t|
      t.references :flight_route, null: false, foreign_key: true
      t.time :departure_time, null: false
      t.time :arrival_time, null: false
      t.integer :days_of_week, array: true, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.boolean :recurring, default: false, null: false

      t.timestamps
    end
  end
end
