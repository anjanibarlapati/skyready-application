require 'rails_helper'

RSpec.describe FlightSearchService, type: :service do
  let(:airline) { create(:airline, name: "IndiGoo") }

  let(:flight_route) {
    create(:flight_route, airline: airline, source: "Delhi", destination: "Mumbai")
  }

  let(:flight) {
    create(:flight, flight_route: flight_route, flight_number: "AI101")
  }

  let(:departure_date) { Date.current + 1 }

  let(:flight_schedule) {
    create(:flight_schedule,
      flight: flight,
      recurring: true,
      start_date: departure_date - 5,
      end_date: departure_date + 5,
      departure_time: "10:00",
      arrival_time: "12:00"
    )
  }

  let!(:schedule_day) {
    create(:flight_schedule_day,
      flight_schedule: flight_schedule,
      day_of_week: departure_date.wday
    )
  }

  let!(:flight_seat) {
    create(:flight_seat,
      flight_schedule: flight_schedule,
      class_type: "Economy",
      total_seats: 100,
      base_price: 3000
    )
  }

  let!(:booking) {
    create(:booking,
      flight_schedule: flight_schedule,
      flight_date: departure_date,
      class_type: "Economy",
      available_seats: 10
    )
  }

  describe ".search" do
    context "when valid inputs are provided" do
      it "returns matching flights" do
        results = described_class.search("Delhi", "Mumbai", departure_date, 1, "Economy")

        expect(results[:found_route]).to be true
        expect(results[:found_class_type]).to be true
        expect(results[:found_date]).to be true
        expect(results[:seats_available]).to be true
        expect(results[:flights].count).to eq(1)

        flight_result = results[:flights].first
        expect(flight_result[:flight_number]).to eq("AI101")
        expect(flight_result[:airline_name]).to eq("IndiGoo")
        expect(flight_result[:class_type]).to eq("Economy")
        expect(flight_result[:seats]).to eq(10)
        expect(flight_result[:base_price]).to eq(3000)
        expect(flight_result[:price]).to be > 3000
      end
    end

    context "when no route is found" do
      it "returns empty results" do
        results = described_class.search("Nowhere", "Imaginary", departure_date, 1, "Economy")

        expect(results[:found_route]).to be false
        expect(results[:flights]).to be_empty
      end
    end

    context "when route is found but no seat available" do
      it "returns found_route true but seats_available false" do
        booking.update!(available_seats: 0)

        results = described_class.search("Delhi", "Mumbai", departure_date, 1, "Economy")

        expect(results[:found_route]).to be true
        expect(results[:found_class_type]).to be true
        expect(results[:found_date]).to be true
        expect(results[:seats_available]).to be false
        expect(results[:flights]).to be_empty
      end
    end
  end

  describe ".calculate_booking_multiplier" do
    it "returns 1.0 when 0–30% booked" do
      expect(described_class.calculate_booking_multiplier(0)).to eq(1.0)
      expect(described_class.calculate_booking_multiplier(30)).to eq(1.0)
    end

    it "returns 1.2 when 31–50% booked" do
      expect(described_class.calculate_booking_multiplier(31)).to eq(1.2)
      expect(described_class.calculate_booking_multiplier(50)).to eq(1.2)
    end

    it "returns 1.35 when 51–75% booked" do
      expect(described_class.calculate_booking_multiplier(51)).to eq(1.35)
      expect(described_class.calculate_booking_multiplier(75)).to eq(1.35)
    end

    it "returns 1.5 when 76–100% booked" do
      expect(described_class.calculate_booking_multiplier(76)).to eq(1.5)
      expect(described_class.calculate_booking_multiplier(100)).to eq(1.5)
    end
  end

  describe ".calculate_date_multiplier" do
    it "returns correct values for near departure dates" do
      expect(described_class.calculate_date_multiplier(3)).to eq(1.15)
      expect(described_class.calculate_date_multiplier(1)).to eq(1.4)
      expect(described_class.calculate_date_multiplier(0)).to eq(1.4)
    end

    it "returns clamped values for mid-range dates" do
      expect(described_class.calculate_date_multiplier(4)).to eq(1.14)
      expect(described_class.calculate_date_multiplier(6)).to eq(1.10)
      expect(described_class.calculate_date_multiplier(10)).to eq(1.02)
    end

    it "returns 1.0 when more than 10 days before" do
      expect(described_class.calculate_date_multiplier(15)).to eq(1.0)
    end
  end
end
