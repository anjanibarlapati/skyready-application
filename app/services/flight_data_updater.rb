require "fileutils"

class FlightDataUpdater
  FLIGHT_DATA_PATH = Rails.root.join("app/assets/data/data.txt")

  def self.reduce_seats(flight_number, departure_date, class_type, travellers_count)
    return false unless File.exist?(FLIGHT_DATA_PATH)

    temp_path = "#{FLIGHT_DATA_PATH}.tmp"
    updated = false

    begin
      File.open(temp_path, "w") do |temp_file|
        File.foreach(FLIGHT_DATA_PATH) do |line|
          fields = line.strip.split(",").map(&:strip)

          departure_dt_str = "#{fields[4]} #{fields[5]}"
          departure_dt = DateTime.parse(departure_dt_str) rescue next

          if fields.size == 17 && fields[0] == flight_number && departure_date == departure_dt
            available = case class_type
            when "Economy"     then fields[9].to_i
            when "Second Class" then fields[11].to_i
            when "First Class"  then fields[13].to_i
            else 0
            end

            if available >= travellers_count
              case class_type
              when "Economy"
                fields[9]  = (available - travellers_count).to_s
              when "Second Class"
                fields[11] = (available - travellers_count).to_s
              when "First Class"
                fields[13] = (available - travellers_count).to_s
              end

              line = fields.join(",") + "\n"
              updated = true
            end
          end

          temp_file.write(line)
        end
      end

      if updated
        FileUtils.mv(temp_path, FLIGHT_DATA_PATH)
      else
        File.delete(temp_path) if File.exist?(temp_path)
      end

      updated
    rescue => e
      File.delete(temp_path) if File.exist?(temp_path)
      false
    end
  end
end
