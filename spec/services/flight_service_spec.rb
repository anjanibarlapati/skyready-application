require "rails_helper"

RSpec.describe FlightService do
  describe ".search" do
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
        available_seats: 20,
        total_seats: 100,
        base_price: 5000
      )
    end

    context "when flights match all criteria" do
      it "returns the flight with correct price" do
        result = FlightService.search("Delhi", "Mumbai", flight.departure_datetime, 2, "Economy")

        expect(result[:found_route]).to be true
        expect(result[:found_date]).to be true
        expect(result[:seats_available]).to be true
        expect(result[:flights].size).to eq(1)

        flight_data = result[:flights].first
        expect(flight_data[:flight_number]).to eq("TA123")
        expect(flight_data[:price]).to be > 5000
      end
    end

    context "when route exists but no flight on given date" do
      it "sets found_route true but found_date false" do
        search_date = flight.departure_datetime + 5.days

        result = FlightService.search("Delhi", "Mumbai", search_date, 1, "Economy")

        expect(result[:found_route]).to be true
        expect(result[:found_date]).to be false
        expect(result[:seats_available]).to be false
        expect(result[:flights]).to be_empty
      end
    end

    context "when route and date match but not enough seats" do
      before do
        economy_seat.update!(available_seats: 1)
      end

      it "sets seats_available false" do
        result = FlightService.search("Delhi", "Mumbai", flight.departure_datetime, 5, "economy")

        expect(result[:found_route]).to be true
        expect(result[:found_date]).to be true
        expect(result[:seats_available]).to be false
        expect(result[:flights]).to be_empty
      end
    end

    context "when no route exists" do
      it "returns all flags false" do
        result = FlightService.search("Chennai", "Kolkata", Time.current + 2.days, 1, "economy")

        expect(result[:found_route]).to be false
        expect(result[:found_date]).to be false
        expect(result[:seats_available]).to be false
        expect(result[:flights]).to be_empty
      end
    end

    context "when class_type is not available on the flight" do
      it "does not include the flight in results" do
        result = FlightService.search("Delhi", "Mumbai", flight.departure_datetime, 1, "First Class")

        expect(result[:found_route]).to be true
        expect(result[:found_date]).to be true
        expect(result[:seats_available]).to be false
        expect(result[:flights]).to be_empty
      end
    end

    context "dynamic pricing" do
      it "increases price as seats get booked (booking multiplier)" do
        economy_seat.update!(available_seats: 50)
        result = FlightService.search("Delhi", "Mumbai", flight.departure_datetime, 1, "Economy")

        flight_price = result[:flights].first[:price]
        expect(flight_price).to be > 5000
      end

      it "increases price as departure date nears (date multiplier)" do
        flight.update!(departure_datetime: Time.current + 1.day)
        result = FlightService.search("Delhi", "Mumbai", flight.departure_datetime, 1, "Economy")

        expect(result[:flights].first[:price]).to be > 5000
      end
      it "applies booking multiplier of 1.0 (no increase)" do
        economy_seat.update!(available_seats: 80, total_seats: 100, base_price: 5000)
        flight.update!(departure_datetime: Time.current + 20.days)

        result = FlightService.search("Delhi", "Mumbai", flight.departure_datetime, 1, "Economy")

        price = result[:flights].first[:price]
        expect(price).to eq(5000)
      end
      it "applies booking multiplier of 1.35" do
        economy_seat.update!(available_seats: 30, total_seats: 100, base_price: 5000)
        flight.update!(departure_datetime: Time.current + 20.days)

        result = FlightService.search("Delhi", "Mumbai", flight.departure_datetime, 1, "Economy")

        price = result[:flights].first[:price]

        expected_price = (5000 + (5000 * 0.35)).to_i
        expect(price).to eq(expected_price)
      end

      it "applies date multiplier between 1.02 and 1.14" do
        flight.update!(departure_datetime: Time.current + 6.days)
        economy_seat.update!(available_seats: 100, total_seats: 100, base_price: 5000)

        result = FlightService.search("Delhi", "Mumbai", flight.departure_datetime, 1, "Economy")

        price = result[:flights].first[:price]

        expected_price = (5000 + (5000 * 0.12)).to_i
        expect(price).to eq(expected_price)
      end
    end

    context "when departure is today but already passed" do
      it "skips the flight" do
        flight.update!(departure_datetime: Time.current - 1.hour)
        result = FlightService.search("Delhi", "Mumbai", Time.current, 1, "Economy")

        expect(result[:found_route]).to be true
        expect(result[:found_date]).to be false
        expect(result[:seats_available]).to be false
        expect(result[:flights]).to be_empty
      end
    end
  end
end
