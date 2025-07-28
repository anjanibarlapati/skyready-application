class FlightBookingService
  def self.book_seats(flight_number, departure_datetime, class_type, travellers_count, use_transaction: true)
    return false if travellers_count <= 0

    flight = Flight.find_by(flight_number: flight_number)
    return false unless flight

    departure_date = departure_datetime.to_date
    departure_time = departure_datetime.to_time.strftime("%H:%M:%S")

    schedule = flight.flight_schedules.find do |s|
      s.departure_time.strftime("%H:%M:%S") == departure_time
    end
    return false unless schedule

    seat = schedule.flight_seats.find_by(class_type: class_type)
    return false unless seat

    booking_logic = -> do
      booking = schedule.bookings.lock.find_by(
        flight_date: departure_date,
        class_type: class_type
      )
      return false unless booking

      return false if booking.available_seats < travellers_count

      booking.available_seats -= travellers_count
      booking.save!
      true
    end

    result = if use_transaction
               Booking.transaction do
                 booking = schedule.bookings.lock.find_by(
                   flight_date: departure_date,
                   class_type: class_type
                 )
                 next false unless booking
                 next false if booking.available_seats < travellers_count

                 booking.available_seats -= travellers_count
                 booking.save!
                 true
               end
    else
               booking_logic.call
    end

    result
  rescue => e
    false
  end

  def self.book_round_trip_seats(departure_flight_number, departure_dt, return_flight_number, return_dt, class_type, travellers_count)
    result = ActiveRecord::Base.transaction do
      success_departure = book_seats(
        departure_flight_number,
        departure_dt,
        class_type,
        travellers_count,
        use_transaction: false
      )

      unless success_departure
        raise ActiveRecord::Rollback, "Departure flight booking failed"
      end

      success_return = book_seats(
        return_flight_number,
        return_dt,
        class_type,
        travellers_count,
        use_transaction: false
      )

      unless success_return
        raise ActiveRecord::Rollback, "Return flight booking failed"
      end

      true
    end

    result == true
  rescue => e
    false
  end
end
