class FlightSearchService
  def self.search(source, destination, departure_date, travellers_count, class_type)
    now = Time.current

    flights = []
    found_route = false
    found_date = false
    seats_available = false
    found_class_type = false

    routes, found_route = find_valid_routes(source, destination)
    return empty_result unless found_route


    flights_for_routes = Flight.where(flight_route_id: routes.select(:id))
    schedules_for_flights = FlightSchedule.where(flight_id: flights_for_routes.select(:id))

    valid_schedules = valid_schedules_for_date(schedules_for_flights, departure_date)
    found_date = valid_schedules.any? do |schedule|
      schedule.bookings.where(flight_date: departure_date).exists?
    end

    found_class_type = valid_schedules.any? do |schedule|
      schedule.flight_seats.where("LOWER(class_type) = ?", class_type.strip.downcase).exists?
    end

    valid_schedules.each do |schedule|
      next if should_skip_schedule_departed_today?(schedule, departure_date, now)

      bookings = find_booking(schedule, departure_date, class_type)
      next if bookings.empty?

      booking = bookings.first

      if booking.available_seats < travellers_count
        next
      end

      seats_available = true

      departure_dt, arrival_dt, date_diff = build_datetime_range(schedule, departure_date)

      price, base_price = calculate_final_price(booking, departure_dt)
      next if price.nil?

      flight_route = schedule.flight.flight_route
      airline = flight_route.airline

      flights << build_flight_result(
        schedule: schedule,
        flight_route: flight_route,
        airline: airline,
        booking: booking,
        departure_dt: departure_dt,
        arrival_dt: arrival_dt,
        date_diff: date_diff,
        price: price,
        base_price: base_price,
        travellers_count: travellers_count,
        class_type: class_type
      )
    end

    {
      flights: flights,
      found_route: found_route,
      found_date: found_date,
      seats_available: seats_available,
      found_class_type: found_class_type
    }
  end

  private

  def self.find_seat(schedule, class_type)
    schedule.flight_seats.where("LOWER(class_type) = ?", class_type.strip.downcase).first
  end

  def self.find_booking(schedule, departure_date, class_type)
    schedule.bookings.where(
      flight_date: departure_date
    ).where("LOWER(class_type) = ?", class_type.strip.downcase)
  end

  def self.should_skip_schedule_departed_today?(schedule, departure_date, now)
    return false unless departure_date == Date.current
    Time.zone.parse("#{departure_date} #{schedule.departure_time}") <= now
  end

  def self.valid_schedules_for_date(schedules_for_flights, departure_date)
    recurring = schedules_for_flights
                  .where(recurring: true)
                  .where("start_date <= ?", departure_date)
                  .where("end_date IS NULL OR end_date >= ?", departure_date)
                  .joins(:flight_schedule_days)
                  .where(flight_schedule_days: { day_of_week: departure_date.wday })

    one_time = schedules_for_flights.where(recurring: false)

    schedules_for_flights
      .where(id: recurring.select(:id))
      .or(one_time)
      .includes(:flight_seats, :bookings, flight: :flight_route)
  end

  def self.find_valid_routes(source, destination)
    routes = FlightRoute.where("LOWER(source) = ? AND LOWER(destination) = ?", source.downcase, destination.downcase)
    return [ nil, false ] unless routes.exists?

    [ routes, true ]
  end

  def self.build_flight_result(schedule:, flight_route:, airline:, booking:, departure_dt:, arrival_dt:, date_diff:, price:, base_price:, travellers_count:, class_type:)
    {
      flight_number: schedule.flight.flight_number,
      airline_name: airline.name,
      source: flight_route.source,
      destination: flight_route.destination,
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

  def self.build_datetime_range(schedule, departure_date)
    departure = Time.zone.parse("#{departure_date} #{schedule.departure_time}")
    arrival   = Time.zone.parse("#{departure_date} #{schedule.arrival_time}")

    adjusted_arrival = arrival < departure ? arrival + 1.day : arrival
    date_diff = (adjusted_arrival.to_date - departure.to_date).to_i

    [ departure, adjusted_arrival, date_diff ]
  end

  def self.empty_result
    {
      found_route: false,
      flights: []
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
