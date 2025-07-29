class FlightBookingService
  def self.book_seats(flight_number, departure_datetime, class_type, travellers_count, use_transaction: true)
    flight = Flight.find_by(flight_number: flight_number)
    return false unless flight

    schedule = find_schedule(flight, departure_datetime)
    return false unless schedule

    return false unless schedule.flight_seats.exists?(class_type: class_type)

    if use_transaction
      book_seats_in_transaction(schedule, departure_datetime.to_date, class_type, travellers_count)
    else
      book_seats_without_transaction(schedule, departure_datetime.to_date, class_type, travellers_count)
    end
  rescue => e
    false
  end


  def self.book_round_trip_seats(departure_flight_number, departure_dt, return_flight_number, return_dt, class_type, travellers_count)
    result = ActiveRecord::Base.transaction do
      book_flight_direction!(departure_flight_number, departure_dt, class_type, travellers_count, :departure)
      book_flight_direction!(return_flight_number, return_dt, class_type, travellers_count, :return)
      true
    end

    result == true
  rescue => e
    false
  end

  def self.book_flight_direction!(flight_number, datetime, class_type, travellers_count, direction)
    success = book_seats(
      flight_number,
      datetime,
      class_type,
      travellers_count,
      use_transaction: false
    )

    unless success
      raise ActiveRecord::Rollback, "#{direction.to_s.capitalize} flight booking failed"
    end
  end

  private

  def self.find_schedule(flight, departure_datetime)
      departure_time = departure_datetime.strftime("%H:%M:%S")
      flight.flight_schedules.find { |s| s.departure_time.strftime("%H:%M:%S") == departure_time }
  end

  def self.book_seats_in_transaction(schedule, date, class_type, count)
    Booking.transaction do
      update_booking(schedule, date, class_type, count)
    end
  end

  def self.book_seats_without_transaction(schedule, date, class_type, count)
    update_booking(schedule, date, class_type, count)
  end

  def self.update_booking(schedule, date, class_type, count)
    booking = schedule.bookings.lock.find_by(flight_date: date, class_type: class_type)
    return false unless booking && booking.available_seats >= count

    booking.available_seats -= count
    booking.save!
    true
  end
end
