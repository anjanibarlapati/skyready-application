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
  let(:departure_datetime) do
    Time.zone.parse("#{booking_date} #{schedule.departure_time}")
  end
  let!(:booking) do
    Booking.create!(
      flight_schedule: schedule,
      flight_date: booking_date,
      class_type: "Economy",
      available_seats: 10
    )
  end

  before { seat }

  describe ".book_seats" do
    context "when seats are available" do
      it "books seats successfully and updates available seats" do
        result = described_class.book_seats(flight.flight_number, departure_datetime, "Economy", 3)
        expect(result).to eq(true)
        expect(booking.reload.available_seats).to eq(7)
      end
    end

    context "when requested seats exceed available seats" do
      it "does not book and returns false" do
        result = described_class.book_seats(flight.flight_number, departure_datetime, "Economy", 20)
        expect(result).to eq(false)
        expect(booking.reload.available_seats).to eq(10)
      end
    end

    context "when flight does not exist" do
      it "returns false" do
        result = described_class.book_seats("INVALID", departure_datetime, "Economy", 1)
        expect(result).to eq(false)
      end
    end

    context "when class_type does not exist for the schedule" do
      it "returns false" do
        result = described_class.book_seats(flight.flight_number, departure_datetime, "First Class", 1)
        expect(result).to eq(false)
      end
    end

    context "when travellers_count is zero or negative" do
      it "returns false" do
        result = described_class.book_seats(flight.flight_number, departure_datetime, "Economy", 0)
        expect(result).to eq(false)
      end
    end

    context "when booking does not exist for the date and class" do
      it "returns false" do
        booking.destroy
        result = described_class.book_seats(flight.flight_number, departure_datetime, "Economy", 1)
        expect(result).to eq(false)
      end
    end
  end
end
