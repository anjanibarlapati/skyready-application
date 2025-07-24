class FlightBookingService
  def self.book_seats(flight_number, departure_datetime, class_type, travellers_count, use_transaction: true)
    return false if travellers_count <= 0

    flight = Flight.find_by(flight_number: flight_number)
    return false unless flight

    departure_date = departure_datetime.to_date
    departure_time = departure_datetime.to_time.strftime("%H:%M:%S")

    schedule = flight.flight_schedules.find_by(departure_time: departure_time)
    return false unless schedule

    seat = schedule.flight_seats.find_by(class_type: class_type)
    return false unless seat

    booking_logic = -> do
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
      true
    end

    use_transaction ? Booking.transaction { booking_logic.call } : booking_logic.call
  rescue => e
    false
  end

  def self.book_round_trip_seats(departure_flight_number, departure_dt, return_flight_number, return_dt, class_type, travellers_count)
    ActiveRecord::Base.transaction do
      success_departure = book_seats(
        departure_flight_number,
        departure_dt,
        class_type,
        travellers_count,
        use_transaction: false
      )

      raise ActiveRecord::Rollback, "Departure flight booking failed" unless success_departure

      success_return = book_seats(
        return_flight_number,
        return_dt,
        class_type,
        travellers_count,
        use_transaction: false
      )

      raise ActiveRecord::Rollback, "Return flight booking failed" unless success_return

      true
    end
  rescue => e
    false
  end
end
