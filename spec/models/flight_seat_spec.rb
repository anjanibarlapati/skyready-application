require 'rails_helper'

RSpec.describe FlightSeat, type: :model do
  let(:airline) { Airline.create!(name: "AirTest") }
  let(:route) do
    FlightRoute.create!(
      airline: airline,
      source: "DEL",
      destination: "BOM"
    )
  end
  let(:flight) do
    Flight.create!(
      flight_number: "AT123",
      flight_route: route
    )
  end
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
      class_type: "Economy",
      total_seats: 100,
      base_price: 5000.0
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is invalid without class_type" do
      subject.class_type = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:class_type]).to include("can't be blank")
    end

    it "is invalid with class_type not in allowed values" do
      subject.class_type = "Luxury"
      expect(subject).not_to be_valid
      expect(subject.errors[:class_type]).to include("is not included in the list")
    end

    it "is invalid without total_seats" do
      subject.total_seats = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:total_seats]).to include("can't be blank")
    end

    it "is invalid with non-integer total_seats" do
      subject.total_seats = 10.5
      expect(subject).not_to be_valid
      expect(subject.errors[:total_seats]).to include("must be an integer")
    end

    it "is invalid with total_seats <= 0" do
      subject.total_seats = 0
      expect(subject).not_to be_valid
      expect(subject.errors[:total_seats]).to include("must be greater than 0")
    end

    it "is invalid without base_price" do
      subject.base_price = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:base_price]).to include("can't be blank")
    end

    it "is invalid with negative base_price" do
      subject.base_price = -100
      expect(subject).not_to be_valid
      expect(subject.errors[:base_price]).to include("must be greater than or equal to 0")
    end

    it "is invalid if class_type is not unique within a flight_schedule" do
      subject.save!
      duplicate = described_class.new(
        flight_schedule: flight_schedule,
        class_type: "Economy",
        total_seats: 80,
        base_price: 4000
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
