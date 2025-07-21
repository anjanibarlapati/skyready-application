require 'rails_helper'

RSpec.describe FlightBookingService do
  describe ".book_seats" do
    let(:airline) { Airline.create!(name: "Test Airline") }

    let(:flight) do
      Flight.create!(
        flight_number: "TA123",
        airline: airline,
        source: "Delhi",
        destination: "Mumbai",
        departure_datetime: Time.current + 2.days,
        arrival_datetime: Time.current + 2.days + 2.hours
      )
    end

    let!(:economy_seat) do
      flight.flight_seats.create!(
        class_type: "Economy",
        available_seats: 10,
        total_seats: 100,
        base_price: 5000
      )
    end

    context "when booking is successful" do
      it "reduces available seats and returns true" do
        result = FlightBookingService.book_seats(flight.flight_number, flight.departure_datetime, "Economy", 3)

        expect(result).to be true
        expect(economy_seat.reload.available_seats).to eq(7)
      end
    end

    context "when travellers_count is zero" do
      it "returns false and does not change seats" do
        result = FlightBookingService.book_seats(flight.flight_number, flight.departure_datetime, "Economy", 0)

        expect(result).to be false
        expect(economy_seat.reload.available_seats).to eq(10)
      end
    end

    context "when travellers_count exceeds available seats" do
      it "returns false and does not change seats" do
        result = FlightBookingService.book_seats(flight.flight_number, flight.departure_datetime, "Economy", 15)

        expect(result).to be false
        expect(economy_seat.reload.available_seats).to eq(10)
      end
    end

    context "when flight does not exist" do
      it "returns false" do
        result = FlightBookingService.book_seats("INVALID", flight.departure_datetime, "Economy", 1)

        expect(result).to be false
      end
    end

    context "when class_type does not exist" do
      it "returns false" do
        result = FlightBookingService.book_seats(flight.flight_number, flight.departure_datetime, "First Class", 1)

        expect(result).to be false
      end
    end

    context "when an unexpected error occurs" do
      it "returns false" do
        allow(Flight).to receive(:find_by).and_raise(StandardError.new("Unexpected error"))

        result = FlightBookingService.book_seats(flight.flight_number, flight.departure_datetime, "Economy", 1)

        expect(result).to be false
      end
    end
  end
end
