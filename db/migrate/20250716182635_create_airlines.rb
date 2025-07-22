class CreateAirlines < ActiveRecord::Migration[8.0]
  def change
    create_table :airlines do |t|
      t.string :name, null: false, primary_key: true
      t.timestamps
    end
  end
end
