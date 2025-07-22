class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.references :flight_schedule, null: false, foreign_key: true
      t.date :flight_date, null: false
      t.string :class_type, null: false
      t.integer :available_seats, null: false

      t.timestamps
    end
  end
end
