class CreateFlightRoutes < ActiveRecord::Migration[7.1]
  def change
    create_table :flight_routes do |t|
      t.string :flight_number, null: false
      t.string :airline_name, null: false
      t.string :source, null: false
      t.string :destination, null: false

      t.timestamps
    end

    add_foreign_key :flight_routes, :airlines, column: :airline_name, primary_key: :name
  end
end
