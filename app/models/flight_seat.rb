class FlightSeat < ApplicationRecord
  belongs_to :flight

  validates :class_type, presence: true, inclusion: { in: [ "Economy", "First Class", "Second Class" ] }
  validates :total_seats, :available_seats, :base_price, presence: true
end
