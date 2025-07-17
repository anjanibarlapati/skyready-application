class CreateFlights < ActiveRecord::Migration[7.1]
  def change
    create_table :flights do |t|
      t.string :flight_number, null: false
      t.references :airline, null: false, foreign_key: true
      t.string :source, null: false
      t.string :destination, null: false
      t.datetime :departure_datetime, null: false
      t.datetime :arrival_datetime, null: false
      t.timestamps
    end

    add_index :flights, [:flight_number, :departure_datetime]
  end
end