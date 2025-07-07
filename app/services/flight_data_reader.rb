class FlightDataReader
  FLIGHT_DATA_PATH = Rails.root.join("app/assets/data/data.txt")

  def self.search(source, destination, departure_date = nil)
    return [] unless File.exist?(FLIGHT_DATA_PATH)

    today = Date.today
    current_time = Time.now.strftime("%H:%M")

    search_date = nil
    if departure_date.present?
      begin
        search_date = Date.parse(departure_date)
      rescue ArgumentError
        return []
      end
    end

    File.readlines(FLIGHT_DATA_PATH).filter_map do |line|
      fields = line.strip.split(",").map(&:strip)
      next unless fields.size == 9

      flight_number, airline_name, from, to, dep_date_str, dep_time, arr_date_str, arr_time, seats_str = fields

      seats = seats_str.to_i
      next if seats == 0
      next unless from.casecmp(source).zero? && to.casecmp(destination).zero?

      begin
        dep_date = Date.parse(dep_date_str)
        arr_date = Date.parse(arr_date_str)
      rescue ArgumentError
        next
      end

      if search_date.present? && dep_date != search_date
        next
      end

      if search_date == today && dep_date == today && dep_time <= current_time
        next
      end

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
        seats: seats
      }
    end
  end
end
