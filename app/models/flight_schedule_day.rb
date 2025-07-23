class FlightScheduleDay < ApplicationRecord
  belongs_to :flight_schedule

  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :day_of_week, uniqueness: { scope: :flight_schedule_id }
end
