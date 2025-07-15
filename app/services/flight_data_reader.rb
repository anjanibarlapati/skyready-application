class FlightDataReader
  FLIGHT_DATA_PATH = Rails.root.join("app/assets/data/data.txt")

  def self.search(source, destination, departure_date, travellers_count, class_type)
    return { flights: [], found_route: false, found_date: false, seats_available: false } unless File.exist?(FLIGHT_DATA_PATH)

  found_route = false
  found_date = false
  seats_available = false

    today = Date.today
    now = Time.now
    current_time = now.strftime("%H:%M")

    flights = File.readlines(FLIGHT_DATA_PATH).filter_map do |line|
      fields = line.strip.split(",").map(&:strip)
      next unless fields.size == 17

      flight_number, airline_name, from, to,
      dep_date_str, dep_time, arr_date_str, arr_time,
      economic_total_str, economic_available_str,
      second_total_str, second_available_str,
      first_total_str, first_available_str,
      economic_price_str, second_class_price_str, first_class_price_str = fields

      class_total = {
        "Economy" => economic_total_str.to_i,
        "Second Class" => second_total_str.to_i,
        "First Class" => first_total_str.to_i
      }

      class_available = {
        "Economy" => economic_available_str.to_i,
        "Second Class" => second_available_str.to_i,
        "First Class" => first_available_str.to_i
      }

      class_prices = {
        "Economy" => economic_price_str.to_i,
        "Second Class" => second_class_price_str.to_i,
        "First Class" => first_class_price_str.to_i
      }
      next unless from.casecmp(source).zero? && to.casecmp(destination).zero?
      found_route = true

      dep_date = Date.parse(dep_date_str) rescue next
      arr_date = Date.parse(arr_date_str) rescue next
      next if dep_date != departure_date
      found_date = true
      flight_time = Time.parse("#{dep_date_str} #{dep_time}") rescue next

      if departure_date == today
        next if flight_time && flight_time <= now
      end

    next if class_available[class_type] < travellers_count
      seats_available = true

    total_seats = class_total[class_type]
    available_seats = class_available[class_type]
    next if total_seats <= 0
    percent_booked = ((total_seats.to_f - available_seats.to_f) / total_seats) * 100

    base_price = class_prices[class_type]

    booking_multiplier =
      if percent_booked >= 0 && percent_booked <= 30.0
        1.0
      elsif percent_booked > 30.0 && percent_booked <= 50.0
        1.2
      elsif percent_booked > 50.0 && percent_booked <= 75.0
        1.35
      else
        1.5
      end

    begin
      days_before_departure = ((flight_time - now) / 86400.0).floor
    rescue ArgumentError
      next
    end


    date_multiplier =
      if days_before_departure >= 0 && days_before_departure <= 3
        (1 + 0.10 * (4.0 - days_before_departure)).clamp(1.10, 1.40)
      elsif days_before_departure > 3 && days_before_departure <= 10
        (1 + 0.02 * (11.0 - days_before_departure)).clamp(1.02, 1.14)
      else
        1.0
      end

    seat_tax = (base_price * (booking_multiplier - 1.0))

    date_tax = (base_price * (date_multiplier - 1.0))

    price = (base_price+ seat_tax + date_tax).to_i


      date_diff = (arr_date - dep_date).to_i
      {
        flight_number: flight_number,
        airline_name: airline_name,
        source: from,
        destination: to,
        departure_date: dep_date.strftime("%Y-%m-%d"),
        departure_time: dep_time,
        arrival_date: arr_date.strftime("%Y-%m-%d"),
        arrival_time: arr_time,
        arrival_date_difference: date_diff > 0 ? "+#{date_diff}" : nil,
        seats: available_seats,
        price: price,
        base_price: base_price,
        travellers_count: travellers_count,
        class_type: class_type
      }

    end
    { flights: flights, found_route: found_route, found_date: found_date, seats_available: seats_available }
end
end
