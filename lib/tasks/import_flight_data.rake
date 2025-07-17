# lib/tasks/import_flight_data.rake

namespace :import do
  desc "Import flights and seats from data.txt"
  task flights: :environment do
    filepath = Rails.root.join("app/assets/data/data.txt")

    File.foreach(filepath) do |line|
      next if line.strip.empty?

      flight_number, airline_name, origin, destination,
      dep_date, dep_time, arr_date, arr_time,
      eco_total, eco_booked, prem_total, prem_booked,
      bus_total, bus_booked,
      eco_fare, prem_fare, bus_fare = line.strip.split(",")

      departure_datetime = DateTime.parse("#{dep_date} #{dep_time}")
      arrival_datetime = DateTime.parse("#{arr_date} #{arr_time}")

      airline = Airline.find_or_create_by!(name: airline_name)

      flight = Flight.create!(
        flight_number: flight_number,
        airline: airline,
        source: origin,
        destination: destination,
        departure_datetime: departure_datetime,
        arrival_datetime: arrival_datetime
      )

      flight.flight_seats.create!([
        {
          class_type: "Economy",
          total_seats: eco_total,
          available_seats:  eco_booked.to_i,
          base_price: eco_fare
        },
        {
          class_type: "First Class",
          total_seats: prem_total,
          available_seats: prem_booked.to_i,
          base_price: prem_fare
        },
        {
          class_type: "Second Class",
          total_seats: bus_total,
          available_seats: bus_booked.to_i,
          base_price: bus_fare
        }
      ])

      puts "✔️ Imported #{flight_number} (#{origin} → #{destination})"
    end

    puts "\n✅ All flight records imported successfully!"
  end
end
