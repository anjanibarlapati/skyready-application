class FlightDataReader
  FLIGHT_DATA_PATH = Rails.root.join("app/assets/data/data.txt")

  def self.search(source, destination, departure_date = nil, travellers_count = 1, class_type = "Economic")
    return [] unless File.exist?(FLIGHT_DATA_PATH)
    class_type = class_type.presence || "Economic"

    today = Date.today
    current_time = Time.now.strftime("%H:%M")

    search_date = Date.parse(departure_date) rescue nil if departure_date.present?
    travellers_count = travellers_count.to_i < 1 ? 1 : travellers_count.to_i

    File.readlines(FLIGHT_DATA_PATH).filter_map do |line|
      fields = line.strip.split(",").map(&:strip)
      next unless fields.size == 18

      flight_number, airline_name, from, to,
      dep_date_str, dep_time, arr_date_str, arr_time,
      economic_total_str, economic_available_str,
      second_total_str, second_available_str,
      first_total_str, first_available_str,
      total_seats_str,
      economic_price_str, second_class_price_str, first_class_price_str = fields

      class_total = {
        "Economic" => economic_total_str.to_i,
        "Second Class" => second_total_str.to_i,
        "First Class" => first_total_str.to_i
      }

      class_available = {
        "Economic" => economic_available_str.to_i,
        "Second Class" => second_available_str.to_i,
        "First Class" => first_available_str.to_i
      }

      class_prices = {
        "Economic" => economic_price_str.to_i,
        "Second Class" => second_class_price_str.to_i,
        "First Class" => first_class_price_str.to_i
      }
      next unless class_available.key?(class_type)
      next unless from.casecmp(source).zero? && to.casecmp(destination).zero?
      next if class_available[class_type] < travellers_count

      dep_date = Date.parse(dep_date_str) rescue next
      arr_date = Date.parse(arr_date_str) rescue next
      next if search_date.present? && dep_date != search_date
      next if search_date == today && dep_date == today && dep_time <= current_time

      total_seats = class_total[class_type]
      available_seats = class_available[class_type]
      percent_booked = ((total_seats.to_f - available_seats.to_f) / total_seats) * 100

      base_price = class_prices[class_type]

     price = if percent_booked >= 0 && percent_booked <= 30.0
          base_price
     elsif percent_booked > 30.0 && percent_booked <= 50.0
          (base_price * 1.2).to_i
     elsif percent_booked > 50.0 && percent_booked <= 75.0
          (base_price * 1.35).to_i
     else
          (base_price * 1.5).to_i
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
        seats: available_seats,
        price: price
      }
    end
  end
end
