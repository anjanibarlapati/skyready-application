class FlightSearchService
  def self.search(source, destination, departure_datetime, travellers_count, class_type)
    flights = []
    found_route = false
    found_date = false
    seats_available = false

    departure_date = departure_datetime.to_date
    now = Time.current.strftime("%Y-%m-%d %H:%M:%S")

    db_flights = Flight
      .includes(:airline, :flight_seats)
      .where("LOWER(source) = ? AND LOWER(destination) = ?", source.downcase, destination.downcase)

    found_route = db_flights.exists?



    db_flights.each do |flight|
      next unless flight.departure_datetime.to_date == departure_date

      if departure_date == Date.current && flight.departure_datetime.strftime("%Y-%m-%d %H:%M:%S") <= now
        next
      end


      found_date = true


      seat = flight.flight_seats.find { |s| s.class_type == class_type }
      next unless seat && seat.available_seats >= travellers_count
      seats_available = true
      price = calculate_final_price(seat, flight.departure_datetime)
      next unless price

      date_diff = (flight.arrival_datetime.to_date - flight.departure_datetime.to_date).to_i

      flights << {
        flight_number: flight.flight_number,
        airline_name: flight.airline.name,
        source: flight.source,
        destination: flight.destination,
        departure_date: flight.departure_datetime.strftime("%Y-%m-%d"),
        departure_time: flight.departure_datetime.strftime("%H:%M"),
        arrival_date: flight.arrival_datetime.strftime("%Y-%m-%d"),
        arrival_time: flight.arrival_datetime.strftime("%H:%M"),
        arrival_date_difference: date_diff > 0 ? "+#{date_diff}" : nil,
        seats: seat.available_seats,
        price: price,
        base_price: seat.base_price,
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

   def self.calculate_final_price(seat, departure_datetime)
    base_price = seat.base_price
    total_seats = seat.total_seats
    available_seats = seat.available_seats

    percent_booked = ((total_seats - available_seats).to_f / total_seats) * 100
    booking_multiplier = calculate_booking_multiplier(percent_booked)

     begin
      days_before_departure = ((departure_datetime - Time.current) / 86400.0).floor
    rescue ArgumentError
      return nil
    end
    date_multiplier = calculate_date_multiplier(days_before_departure)

    seat_tax = base_price * (booking_multiplier - 1)
    date_tax = base_price * (date_multiplier - 1)

    (base_price + seat_tax + date_tax).to_i
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
    if days_before_departure >= 0 && days_before_departure <= 3
      (1 + 0.15 * (4.0 - days_before_departure)).clamp(1.10, 1.40)
    elsif days_before_departure > 3 && days_before_departure <= 10
      (1 + 0.02 * (11.0 - days_before_departure)).clamp(1.02, 1.14)
    else
      1.0
    end
  end
end
