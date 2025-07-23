class CreateFlights < ActiveRecord::Migration[7.0]
  def change
    create_table :flights do |t|
      t.references :flight_route, null: false, foreign_key: true
      t.string :flight_number, null: false

      t.timestamps
    end
    add_index :flights, :flight_number, unique: true
  end
end
