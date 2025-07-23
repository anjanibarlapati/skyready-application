require 'rails_helper'

RSpec.describe FlightBookingService, type: :service do
  let(:flight) { Flight.create!(flight_number: "AI101", flight_route: create(:flight_route)) }
  let(:schedule) do
    FlightSchedule.create!(
      flight: flight,
      departure_time: "10:00:00",
      arrival_time: "12:00:00",
      start_date: Date.today,
      recurring: false
    )
  end
  let(:seat) do
    FlightSeat.create!(
      flight_schedule: schedule,
      class_type: "Economy",
      total_seats: 100,
      base_price: 5000
    )
  end
  let(:booking_date) { Date.today }
  let(:departure_datetime) { DateTime.parse("#{booking_date} 10:00:00") }
  let!(:booking) do
    Booking.create!(
      flight_schedule: schedule,
      flight_date: booking_date,
      class_type: "Economy",
      available_seats: 10
    )
  end

  describe ".book_seats" do
    before { seat }
    it "books seats when available" do
      result = described_class.book_seats(flight.flight_number, departure_datetime, "Economy", 3)
      expect(result).to eq(true)
      expect(booking.reload.available_seats).to eq(7)
    end
    it "does not book if not enough seats" do
    result = described_class.book_seats(flight.flight_number, departure_datetime, "Economy", 20)
    expect(result).to eq(false)
    expect(booking.reload.available_seats).to eq(10)
    end

    it "does not book if flight does not exist" do
    result = described_class.book_seats("INVALID", departure_datetime, "Economy", 1)
    expect(result).to eq(false)
    end

    it "does not book if class_type does not exist" do
    result = described_class.book_seats(flight.flight_number, departure_datetime, "First Class", 1)
    expect(result).to eq(false)
    end

    it "does not book if travellers_count is zero or negative" do
    result = described_class.book_seats(flight.flight_number, departure_datetime, "Economy", 0)
    expect(result).to eq(false)
    end

    it "does not book if booking does not exist for date/class" do
    # Remove the booking
    booking.destroy
    result = described_class.book_seats(flight.flight_number, departure_datetime, "Economy", 1)
    expect(result).to eq(false)
    end
  end
end
