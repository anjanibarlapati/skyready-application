class FlightSeat < ApplicationRecord
  belongs_to :flight_schedule

  CLASS_TYPES = [ "Economy", "Second Class", "First Class" ].freeze

  validates :class_type, presence: true, inclusion: { in: CLASS_TYPES }
  validates :total_seats, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :base_price, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
