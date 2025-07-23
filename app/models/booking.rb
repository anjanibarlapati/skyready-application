class Booking < ApplicationRecord
  belongs_to :flight_schedule

  CLASS_TYPES = [ "Economy", "Second Class", "First Class" ].freeze

  validates :flight_date, :class_type, :available_seats, presence: true
  validates :class_type, uniqueness: { scope: [ :flight_schedule_id, :flight_date ] }, inclusion: { in: CLASS_TYPES }
  validates :available_seats, numericality: { greater_than_or_equal_to: 0 }
end
