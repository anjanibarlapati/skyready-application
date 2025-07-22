class FlightSearchService
  def self.search(source, destination, departure_datetime, travellers_count, class_type)
    departure_date = departure_datetime.to_date
    now = Time.current

    flights = []
    found_route = false
    found_date = false
    seats_available = false

    routes = FlightRoute.where("LOWER(source) = ? AND LOWER(destination) = ?", source.downcase, destination.downcase)
    found_route = routes.exists?
    return empty_result unless found_route


    recurring = FlightSchedule
                  .where(flight_route: routes, recurring: true)
                  .where("start_date <= ?", departure_date)
                  .where("end_date IS NULL OR end_date >= ?", departure_date)
                  .where("? = ANY(days_of_week)", departure_date.wday)

    one_time = FlightSchedule
                 .where(flight_route: routes, recurring: false)

    valid_schedules = FlightSchedule
                        .where(id: recurring.select(:id))
                        .or(one_time)
                        .includes(:flight_route, :bookings)

    valid_schedules.each do |schedule|
      if departure_date == Date.current
        flight_time = Time.zone.parse("#{departure_date} #{schedule.departure_time}")
        next if flight_time <= now
      end

      bookings = schedule.bookings.select do |b|
        b.flight_date.to_date == departure_date &&
          b.class_type.to_s.strip.downcase == class_type.strip.downcase
      end

      if bookings.empty?
        next
      end

      booking = bookings.first
      found_date = true

      if booking.available_seats < travellers_count
        next
      end

      seats_available = true

      price, base_price = calculate_final_price(booking, departure_datetime)

      if price.nil?
        next
      end

      departure_dt = Time.zone.parse("#{departure_date} #{schedule.departure_time}")
      arrival_dt   = Time.zone.parse("#{departure_date} #{schedule.arrival_time}")
      arrival_dt += 1.day if arrival_dt < departure_dt
      date_diff = (arrival_dt.to_date - departure_dt.to_date).to_i

      flights << {
        flight_number: schedule.flight_route.flight_number,
        airline_name: schedule.flight_route.airline_name,
        source: schedule.flight_route.source,
        destination: schedule.flight_route.destination,
        departure_date: departure_dt.strftime("%Y-%m-%d"),
        departure_time: departure_dt.strftime("%H:%M"),
        arrival_date: arrival_dt.strftime("%Y-%m-%d"),
        arrival_time: arrival_dt.strftime("%H:%M"),
        arrival_date_difference: date_diff.positive? ? "+#{date_diff}" : nil,
        seats: booking.available_seats,
        price: price,
        base_price: base_price,
        travellers_count: travellers_count,
        class_type: class_type
      }
    end

    {
      flights: flights,
      found_route: found_route,
      found_date: found_date,
      seats_available: seats_available
    }
  end

  private

  def self.empty_result
    {
      flights: [],
      found_route: false,
      found_date: false,
      seats_available: false
    }
  end

  def self.calculate_final_price(booking, departure_datetime)
    seat = FlightSeat.find_by(
      flight_schedule_id: booking.flight_schedule_id,
      class_type: booking.class_type
    )

    unless seat
      return nil
    end

    base_price = seat.base_price
    total_seats = seat.total_seats
    available_seats = booking.available_seats

    percent_booked = ((total_seats - available_seats).to_f / total_seats) * 100
    booking_multiplier = calculate_booking_multiplier(percent_booked)

    days_before_departure = ((departure_datetime - Time.current) / 86400.0).floor
    date_multiplier = calculate_date_multiplier(days_before_departure)

    seat_tax = base_price * (booking_multiplier - 1)
    date_tax = base_price * (date_multiplier - 1)

    final_price = (base_price + seat_tax + date_tax).to_i

    [ final_price, base_price ]
  rescue => e
    nil
  end

  def self.calculate_booking_multiplier(percent_booked)
    if percent_booked >= 0 && percent_booked <= 30.0
        1.0
    elsif percent_booked > 30.0 && percent_booked <= 50.0
        1.2
    elsif percent_booked > 50.0 && percent_booked <= 75.0
        1.35
    else
        1.5
    end
  end

  def self.calculate_date_multiplier(days_before_departure)
    if days_before_departure <= 3
      (1 + 0.15 * (4 - days_before_departure)).clamp(1.10, 1.40)
    elsif days_before_departure <= 10
      (1 + 0.02 * (11 - days_before_departure)).clamp(1.02, 1.14)
    else
      1.0
    end
  end
end
