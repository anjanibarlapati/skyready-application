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

    it "DEBUG: step by step service execution" do
      puts "\n=== COMPREHENSIVE DEBUG ==="
      puts "Rails.env: #{Rails.env}"
      puts "Time.zone: #{Time.zone}"
      puts "ActiveRecord adapter: #{ActiveRecord::Base.connection.adapter_name}"

      puts "\n1. Testing travellers_count validation:"
      result_zero = described_class.book_seats(flight.flight_number, departure_datetime, "Economy", 0)
      puts "   Result with 0 travellers: #{result_zero} (should be false)"

      puts "\n2. Testing flight lookup:"
      puts "   flight.flight_number: '#{flight.flight_number}'"
      found_flight = Flight.find_by(flight_number: flight.flight_number)
      puts "   Flight found: #{found_flight.present?}"

      puts "\n3. Testing date/time processing:"
      departure_date_processed = departure_datetime.to_date
      departure_time_processed = departure_datetime.to_time.strftime("%H:%M:%S")
      puts "   departure_datetime: #{departure_datetime}"
      puts "   departure_date_processed: #{departure_date_processed}"
      puts "   departure_time_processed: '#{departure_time_processed}'"

      puts "\n4. Testing schedule lookup:"
      puts "   Looking for schedule with departure_time: '#{departure_time_processed}'"
      # FIXED: Use PostgreSQL time formatting to match time portion only
      found_schedule = found_flight.flight_schedules.where(
        "TO_CHAR(departure_time, 'HH24:MI:SS') = ?",
        departure_time_processed
      ).first
      puts "   Schedule found: #{found_schedule.present?}"
      all_schedules = found_flight.flight_schedules.all
      puts "   All schedules: #{all_schedules.present?}"
      puts "   Number of schedules: #{all_schedules.count}"

      # To see the actual schedules with their details:
      puts "   Schedule details:"
      all_schedules.each_with_index do |schedule, index|
        puts "     #{index + 1}. ID: #{schedule.id}, departure_time: '#{schedule.departure_time}' (#{schedule.departure_time.class})"
      end

      if found_schedule
        puts "   Schedule ID: #{found_schedule.id}"
        puts "   Schedule departure_time: '#{found_schedule.departure_time}'"
        puts "   Schedule departure_time class: #{found_schedule.departure_time.class}"
      else
        puts "   Available schedules:"
        found_flight.flight_schedules.each do |sch|
          puts "     - ID: #{sch.id}, departure_time: '#{sch.departure_time}' (#{sch.departure_time.class})"
        end
      end

      puts "\n5. Testing seat lookup:"
      if found_schedule
        found_seat = found_schedule.flight_seats.find_by(class_type: "Economy")
        puts "   Seat found: #{found_seat.present?}"
        if found_seat
          puts "   Seat ID: #{found_seat.id}"
        else
          puts "   Available seats:"
          found_schedule.flight_seats.each do |seat|
            puts "     - ID: #{seat.id}, class_type: '#{seat.class_type}'"
          end
        end
      end

       puts "\n6. Testing booking lookup:"
      if found_schedule
        found_booking = found_schedule.bookings.find_by(
          flight_date: departure_date_processed,
          class_type: "Economy"
        )
        puts "   Booking found: #{found_booking.present?}"
        if found_booking
          puts "   Booking ID: #{found_booking.id}"
          puts "   Available seats: #{found_booking.available_seats}"
          puts "   Flight date: #{found_booking.flight_date}"
          puts "   Class type: '#{found_booking.class_type}'"
        else
          puts "   Available bookings:"
          found_schedule.bookings.each do |book|
            puts "     - ID: #{book.id}, flight_date: #{book.flight_date}, class_type: '#{book.class_type}', seats: #{book.available_seats}"
          end
        end
      end

      puts "\n7. Testing actual service call:"
      result = described_class.book_seats(
        flight.flight_number,
        departure_datetime,
        "Economy",
        3
      )
      puts "   Service result: #{result}"
      puts "   Booking seats after call: #{booking.reload.available_seats}"

      puts "=== END DEBUG ==="
    end

    it "DEBUG: manual service logic replication" do
      puts "\n=== MANUAL LOGIC TEST ==="

      travellers_count = 3

      return_early_1 = travellers_count <= 0
      puts "Should return early (travellers <= 0): #{return_early_1}"

      flight_found = Flight.find_by(flight_number: flight.flight_number)
      return_early_2 = flight_found.nil?
      puts "Should return early (flight not found): #{return_early_2}"

      departure_date = departure_datetime.to_date
      departure_time = departure_datetime.to_time.strftime("%H:%M:%S")
      # FIXED: Use PostgreSQL time formatting to match time portion only
      schedule_found = flight_found.flight_schedules.where(
        "TO_CHAR(departure_time, 'HH24:MI:SS') = ?",
        departure_time
      ).first
      return_early_3 = schedule_found.nil?
      puts "Should return early (schedule not found): #{return_early_3}"
      puts "departure_time used for lookup: '#{departure_time}'"

      if schedule_found
        seat_found = schedule_found.flight_seats.find_by(class_type: "Economy")
        return_early_4 = seat_found.nil?
        puts "Should return early (seat not found): #{return_early_4}"
      end

      if schedule_found && !return_early_4
        puts "Entering transaction logic..."

        begin
          result = Booking.transaction do
            booking_found = schedule_found.bookings.lock.find_by(
              flight_date: departure_date,
              class_type: "Economy"
            )
            puts "Booking found in transaction: #{booking_found.present?}"

            if booking_found.nil?
              puts "Booking not found, returning false"
              next false
            end

            if booking_found.available_seats < travellers_count
              puts "Not enough seats (#{booking_found.available_seats} < #{travellers_count})"
              next false
            end

            puts "Before update: #{booking_found.available_seats} seats"
            booking_found.available_seats -= travellers_count
            save_result = booking_found.save!
            puts "Save result: #{save_result}"
            puts "After update: #{booking_found.available_seats} seats"

            true
          end

          puts "Transaction result: #{result}"
        rescue => e
          puts "Exception caught: #{e.class}: #{e.message}"
          result = false
        end
      end

      puts "=== END MANUAL LOGIC ==="
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
