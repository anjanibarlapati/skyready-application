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
      next unless fields.size == 7

      flight_number, airline_name, from, to, date_str, departure_time, arrival_time = fields


      next unless from.casecmp(source).zero? && to.casecmp(destination).zero?

      begin
        flight_date = Date.parse(date_str)
      rescue ArgumentError
        next
      end

      if search_date.present? && flight_date != search_date
        next
      end

      if search_date == today && flight_date == today && departure_time <= current_time
        next
      end

      {
        flight_number: flight_number,
        airline_name: airline_name,
        source: from,
        destination: to,
        departure_date: flight_date.strftime("%Y-%m-%d"),
        departure_time: departure_time,
        arrival_time: arrival_time
      }
    end
  end
end
