class CreateBookings < ActiveRecord::Migration[7.0]
  def change
    create_table :bookings do |t|
      t.references :flight_schedule, null: false, foreign_key: true
      t.date :flight_date, null: false
      t.string :class_type, null: false
      t.integer :available_seats, null: false

      t.timestamps
    end

    add_index :bookings, [ :flight_schedule_id, :class_type, :flight_date ], unique: true, name: "index_bookings_on_schedule_id_and_class_date"
  end
end
