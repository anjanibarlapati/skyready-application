class FlightSchedule < ApplicationRecord
  belongs_to :flight_route
  has_many :bookings, dependent: :destroy

  has_many :flight_seats, dependent: :destroy

  validates :departure_time, :arrival_time, :start_date, presence: true
  validates :days_of_week, presence: true, if: :recurring?

  validate :end_date_after_start_date
  validate :days_of_week_valid, if: -> { days_of_week.present? }

  private

  def end_date_after_start_date
    if start_date.present? && end_date.present? && end_date < start_date
      errors.add(:end_date, "must be after start_date")
    end
  end

  def days_of_week_valid
    unless days_of_week.all? { |day| (0..6).include?(day) }
      errors.add(:days_of_week, "must contain values between 0 (Sunday) and 6 (Saturday)")
    end
  end
end
