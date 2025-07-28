require "rails_helper"

RSpec.describe FlightBookingService do
  let(:flight) { create(:flight) }
  let(:departure_time) { "10:00:00" }
  let(:arrival_time) { "12:00:00" }
  let(:departure_date) { Date.today + 1 }
  let(:departure_datetime) { Time.zone.parse("#{departure_date} #{departure_time}") }

  describe ".book_seats" do
    let(:schedule) do
      create(:flight_schedule,
        flight: flight,
        departure_time: departure_time,
        arrival_time: arrival_time)
    end

    let!(:flight_seat) do
      create(:flight_seat,
        flight_schedule: schedule,
        class_type: "Economy")
    end

    let!(:booking) do
      create(:booking,
        flight_schedule: schedule,
        flight_date: departure_date,
        class_type: "Economy",
        available_seats: 10)
    end

    it "returns true and books seats successfully" do
      result = described_class.book_seats(
        flight.flight_number,
        departure_datetime,
        "Economy",
        3
      )
      expect(result).to be true
      expect(booking.reload.available_seats).to eq(7)
    end

    it "returns false if travellers_count is zero" do
      result = described_class.book_seats(
        flight.flight_number,
        departure_datetime,
        "Economy",
        0
      )
      expect(result).to be false
    end

    it "returns false if flight is not found" do
      result = described_class.book_seats(
        "INVALID123",
        departure_datetime,
        "Economy",
        1
      )
      expect(result).to be false
    end

    it "returns false if schedule is not found" do
      result = described_class.book_seats(
        flight.flight_number,
        Time.zone.parse("2025-12-31 20:00:00"),
        "Economy",
        1
      )
      expect(result).to be false
    end

    it "returns false if flight seat is not found" do
      flight_seat.destroy
      result = described_class.book_seats(
        flight.flight_number,
        departure_datetime,
        "Economy",
        1
      )
      expect(result).to be false
    end

    it "returns false if not enough available seats" do
      booking.update!(available_seats: 2)
      result = described_class.book_seats(
        flight.flight_number,
        departure_datetime,
        "Economy",
        5
      )
      expect(result).to be false
    end

    it "returns false when an exception is raised during booking" do
      allow_any_instance_of(ActiveRecord::Relation).to receive(:find_by).and_raise(StandardError, "Simulated failure")

      result = described_class.book_seats(
        flight.flight_number,
        departure_datetime,
        "Economy",
        1
      )

      expect(result).to be false
    end
  end

  describe ".book_round_trip_seats" do
    let(:departure_flight) { create(:flight) }
    let(:return_flight) { create(:flight) }

    let(:departure_time) { "10:00:00" }
    let(:return_time) { "18:00:00" }
    let(:departure_arrival_time) { "12:00:00" }
    let(:return_arrival_time) { "20:00:00" }

    let(:departure_date) { Date.today + 1 }
    let(:return_date) { Date.today + 5 }

    let(:departure_dt) { Time.zone.parse("#{departure_date} #{departure_time}") }
    let(:return_dt) { Time.zone.parse("#{return_date} #{return_time}") }

    let(:departure_schedule) do
      create(:flight_schedule,
        flight: departure_flight,
        departure_time: departure_time,
        arrival_time: departure_arrival_time)
    end

    let(:return_schedule) do
      create(:flight_schedule,
        flight: return_flight,
        departure_time: return_time,
        arrival_time: return_arrival_time)
    end

    let!(:departure_seat) do
      create(:flight_seat,
        flight_schedule: departure_schedule,
        class_type: "Economy")
    end

    let!(:return_seat) do
      create(:flight_seat,
        flight_schedule: return_schedule,
        class_type: "Economy")
    end

    let!(:departure_booking) do
      create(:booking,
        flight_schedule: departure_schedule,
        flight_date: departure_date,
        class_type: "Economy",
        available_seats: 10)
    end

    let!(:return_booking) do
      create(:booking,
        flight_schedule: return_schedule,
        flight_date: return_date,
        class_type: "Economy",
        available_seats: 10)
    end

    it "returns true when both departure and return flights are booked" do
      result = described_class.book_round_trip_seats(
        departure_flight.flight_number,
        departure_dt,
        return_flight.flight_number,
        return_dt,
        "Economy",
        2
      )

      expect(result).to be true
      expect(departure_booking.reload.available_seats).to eq(8)
      expect(return_booking.reload.available_seats).to eq(8)
    end

    it "returns false if departure booking fails" do
      departure_booking.update!(available_seats: 0)

      result = described_class.book_round_trip_seats(
        departure_flight.flight_number,
        departure_dt,
        return_flight.flight_number,
        return_dt,
        "Economy",
        2
      )

      expect(result).to be_falsey
    end

    it "returns false if return booking fails" do
      return_booking.update!(available_seats: 1)

      result = described_class.book_round_trip_seats(
        departure_flight.flight_number,
        departure_dt,
        return_flight.flight_number,
        return_dt,
        "Economy",
        2
      )

      expect(result).to be_falsey
    end

    it "returns false if an unexpected exception is raised during round trip booking" do
      allow(FlightBookingService).to receive(:book_seats).and_raise(StandardError.new("Simulated crash"))

      result = described_class.book_round_trip_seats(
        departure_flight.flight_number,
        departure_dt,
        return_flight.flight_number,
        return_dt,
        "Economy",
        1
      )

      expect(result).to be false
    end
  end
end