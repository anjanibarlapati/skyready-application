class CreateAirlines < ActiveRecord::Migration[8.0]
  def change
    create_table :airlines do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :airlines, :name, unique: true
  end
end
