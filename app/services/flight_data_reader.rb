class FlightDataReader
  FLIGHT_DATA_PATH = Rails.root.join("app/assets/data/data.txt")

  def self.search(source, destination)
    return [] unless File.exist?(FLIGHT_DATA_PATH)

    File.readlines(FLIGHT_DATA_PATH).filter_map do |line|
      flight_number, from, to = line.strip.split(",")

      if from.casecmp(source).zero? && to.casecmp(destination).zero?
        { flight_number: flight_number, source: from, destination: to }
      end
    end
  end
end
