class FlightBookingService
  def self.book_seats(flight_number, departure_datetime, class_type, travellers_count)
    return false if travellers_count <= 0

    flight = Flight.find_by(flight_number: flight_number)
    return false unless flight

    departure_date = departure_datetime.to_date
    departure_time = departure_datetime.to_time.strftime("%H:%M:%S")

    schedule = flight.flight_schedules.find_by(departure_time: departure_time)
    return false unless schedule

    seat = schedule.flight_seats.find_by(class_type: class_type)
    return false unless seat

    Booking.transaction do
      booking = schedule.bookings.lock.find_by(
        flight_date: departure_date,
        class_type: class_type
      )
      return false unless booking

      if booking.available_seats < travellers_count
        return false
      end

      booking.available_seats -= travellers_count
      booking.save!
      return true
    end
  rescue => e
    Rails.logger.error "Booking failed: #{e.message}"
    false
  end
end
