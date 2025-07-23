class CreateFlightRoutes < ActiveRecord::Migration[7.0]
  def change
    create_table :flight_routes do |t|
      t.references :airline, null: false, foreign_key: true
      t.string :source, null: false
      t.string :destination, null: false

      t.timestamps
    end
    add_index :flight_routes, [ :airline_id, :source, :destination ], unique: true
  end
end
