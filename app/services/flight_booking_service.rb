class FlightBookingService
    def self.book_seats(flight_number, departure_datetime, class_type, travellers_count)
        return false if travellers_count <= 0

        Flight.transaction do
        flight = Flight.find_by(
            flight_number: flight_number,
            departure_datetime: departure_datetime
        )
        return false unless flight

        seat = flight.flight_seats.find_by(class_type: class_type)
        return false unless seat

        seat.with_lock do
            if seat.available_seats >= travellers_count
            seat.available_seats -= travellers_count
            seat.save!
            return true
            else
            return false
            end
        end
        end
    rescue => e
        false
    end
end
