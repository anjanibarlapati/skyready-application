class CreateFlightSeats < ActiveRecord::Migration[8.0]
  def change
    create_table :flight_seats do |t|
      t.references :flight, null: false, foreign_key: true
      t.string :class_type, null: false
      t.integer :total_seats, null: false
      t.integer :available_seats, null: false
      t.integer :base_price, null: false

      t.timestamps
    end
  end
end
