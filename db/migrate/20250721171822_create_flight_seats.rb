class CreateFlightSeats < ActiveRecord::Migration[7.1]
  def change
    create_table :flight_seats do |t|
      t.references :flight_schedule, null: false, foreign_key: true
      t.string :class_type, null: false
      t.integer :total_seats, null: false
      t.integer :base_price, null: false

      t.timestamps
    end
  end
end
