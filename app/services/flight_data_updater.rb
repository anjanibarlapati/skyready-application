class FlightDataUpdater
  FLIGHT_DATA_PATH = Rails.root.join("app/assets/data/data.txt")

  def self.reduce_seats(flight_number, departure_date, class_type, travellers_count)
    return unless File.exist?(FLIGHT_DATA_PATH)
    lines = File.readlines(FLIGHT_DATA_PATH)
    updated_lines = lines.map do |line|
      fields = line.strip.split(",").map(&:strip)
      next line unless fields.size == 18

      if fields[0] == flight_number && fields[4] == departure_date

        case class_type
        when "Economic"
            fields[9]  = [ fields[9].to_i - travellers_count, 0 ].max.to_s
        when "Second Class"
            fields[11] = [ fields[11].to_i - travellers_count, 0 ].max.to_s
        when "First Class"
            fields[13] = [ fields[13].to_i - travellers_count, 0 ].max.to_s
        end
        fields[14] = [ fields[14].to_i - travellers_count, 0 ].max.to_s
        line = fields.join(",") + "\n"
      end

      line
    end

    File.write(FLIGHT_DATA_PATH, updated_lines.join)
  end
end
