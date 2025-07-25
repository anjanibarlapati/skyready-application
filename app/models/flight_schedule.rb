class FlightSchedule < ApplicationRecord
  belongs_to :flight
  has_many :flight_schedule_days, dependent: :destroy
  has_many :flight_seats, dependent: :destroy
  has_many :bookings, dependent: :destroy

  validates :departure_time, :arrival_time, :start_date, presence: true
  validates :recurring, inclusion: { in: [ true, false ] }

  validates :departure_time, uniqueness: {
    scope: [ :flight_id, :arrival_time, :start_date, :end_date ],
    message: "with same time and dates already exists for this flight"
  }

  validate :no_overlapping_time_slots

  private

  def no_overlapping_time_slots
    return if departure_time.blank? || arrival_time.blank?

    overlapping_schedules = FlightSchedule
      .where(flight_id: flight_id)
      .where(recurring: recurring)
      .where(
        "(departure_time < ? AND arrival_time > ?) OR
        (departure_time < ? AND arrival_time > ?) OR
        (departure_time >= ? AND arrival_time <= ?)",
        arrival_time, arrival_time,
        departure_time, departure_time,
        departure_time, arrival_time
      )

    if overlapping_schedules.exists?
      errors.add(:base, "Flight schedule overlaps with an existing schedule for this flight")
    end
  end
end
