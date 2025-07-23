require 'rails_helper'

RSpec.describe Booking, type: :model do
  let(:airline) { Airline.create!(name: "TestAir") }
  let(:route) { FlightRoute.create!(airline: airline, source: "DEL", destination: "BOM") }
  let(:flight) { Flight.create!(flight_route: route, flight_number: "TA123") }
  let(:flight_schedule) do
    FlightSchedule.create!(
      flight: flight,
      departure_time: Time.zone.parse("10:00"),
      arrival_time: Time.zone.parse("12:00"),
      start_date: Date.today,
      recurring: true
    )
  end

  subject do
    described_class.new(
      flight_schedule: flight_schedule,
      flight_date: Date.today + 1,
      class_type: "Economy",
      available_seats: 5
    )
  end

  describe "validations" do
    it "is valid with all valid attributes" do
      expect(subject).to be_valid
    end

    it "is invalid without flight_date" do
      subject.flight_date = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:flight_date]).to include("can't be blank")
    end

    it "is invalid without class_type" do
      subject.class_type = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:class_type]).to include("can't be blank")
    end

    it "is invalid with class_type not in allowed list" do
      subject.class_type = "Business"
      expect(subject).not_to be_valid
      expect(subject.errors[:class_type]).to include("is not included in the list")
    end

    it "is invalid without available_seats" do
      subject.available_seats = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:available_seats]).to include("can't be blank")
    end

    it "is invalid with negative available_seats" do
      subject.available_seats = -1
      expect(subject).not_to be_valid
      expect(subject.errors[:available_seats]).to include("must be greater than or equal to 0")
    end

    it "is invalid if class_type is not unique for same flight_schedule and flight_date" do
      subject.save!
      duplicate = Booking.new(
        flight_schedule: flight_schedule,
        flight_date: subject.flight_date,
        class_type: "Economy",
        available_seats: 3
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:class_type]).to include("has already been taken")
    end
  end

  describe "associations" do
    it "belongs to flight_schedule" do
      assoc = described_class.reflect_on_association(:flight_schedule)
      expect(assoc.macro).to eq(:belongs_to)
    end
  end
end
