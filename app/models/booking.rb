class Booking < ApplicationRecord
  belongs_to :flight_schedule

  CLASS_TYPES = [ "Economy", "Second Class", "First Class" ].freeze

  validates :flight_date, :class_type, :available_seats, presence: true
  validates :class_type, inclusion: { in: CLASS_TYPES }
  validates :available_seats, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
