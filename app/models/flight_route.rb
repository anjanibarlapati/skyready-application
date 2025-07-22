class FlightRoute < ApplicationRecord
  belongs_to :airline, foreign_key: :airline_name, primary_key: :name

  validates :flight_number, :airline_name, :source, :destination, presence: true

  validates :flight_number, uniqueness: {
    scope: [ :source, :destination ],
    message: "with this source and destination already exists"
  }
end
