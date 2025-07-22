require 'rails_helper'

RSpec.describe FlightSearchService, type: :service do
  let(:airline) { create(:airline, name: "IndiGoo") }

  let(:flight_route) {
    create(
      :flight_route,
      airline_name: airline.name,
      flight_number: "AI101",
      source: "Delhi",
      destination: "Mumbai"
    )
  }

  let(:future_date) { Date.today + 1 }

  let(:flight_schedule) {
    create(
      :flight_schedule,
      flight_route: flight_route,
      recurring: true,
      start_date: future_date - 5,
      end_date: future_date + 5,
      days_of_week: [ future_date.wday ],
      departure_time: "10:00",
      arrival_time: "12:00"
    )
  }

  let(:flight_seat) {
    create(
      :flight_seat,
      flight_schedule: flight_schedule,
      class_type: "Economy",
      total_seats: 100,
      base_price: 3000
    )
  }

  let!(:booking) {
    create(
      :booking,
      flight_schedule: flight_schedule,
      flight_date: future_date,
      class_type: "Economy",
      available_seats: 10
    )
  }

  describe ".search" do
    context "when valid inputs are provided" do
      it "returns matching flights" do
        flight_seat
        results = described_class.search("Delhi", "Mumbai", Time.zone.parse("#{future_date} 10:00"), 1, "Economy")

        expect(results[:found_route]).to be true
        expect(results[:found_date]).to be true
        expect(results[:seats_available]).to be true
        expect(results[:flights].count).to eq(1)

        flight = results[:flights].first
        expect(flight[:flight_number]).to eq("AI101")
        expect(flight[:airline_name]).to eq("IndiGoo")
        expect(flight[:class_type]).to eq("Economy")
        expect(flight[:seats]).to eq(10)
        expect(flight[:price]).to be_present
        expect(flight[:base_price]).to eq(3000)
      end
    end

    context "when no route is found" do
      it "returns empty results" do
        results = described_class.search("NonExistent", "Nowhere", Time.zone.now, 1, "Economy")

        expect(results[:found_route]).to be false
        expect(results[:flights]).to be_empty
      end
    end

    context "when route is found but no seat available" do
      it "returns found_route true but seats_available false" do
        booking.update!(available_seats: 0)

        results = described_class.search("Delhi", "Mumbai", Time.zone.parse("#{Date.today} 10:00"), 1, "Economy")

        expect(results[:found_route]).to be true
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
    it "returns 1.15 when 3 days before departure" do
      expect(described_class.calculate_date_multiplier(3)).to eq(1.15)
    end

    it "returns 1.4 when 1 day before departure" do
      expect(described_class.calculate_date_multiplier(1)).to eq(1.4)
    end

    it "returns 1.0 when more than 10 days before departure" do
      expect(described_class.calculate_date_multiplier(15)).to eq(1.0)
    end
    it "returns 1.14 when 4 days before departure (upper bound clamp)" do
      expect(described_class.calculate_date_multiplier(4)).to eq(1.14)
    end

    it "returns 1.10 when 6 days before departure (within range)" do
      expect(described_class.calculate_date_multiplier(6)).to eq(1.10)
    end

    it "returns 1.02 when 10 days before departure (lower bound clamp)" do
      expect(described_class.calculate_date_multiplier(10)).to eq(1.02)
    end
  end
end
