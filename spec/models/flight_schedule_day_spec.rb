require 'rails_helper'

RSpec.describe FlightScheduleDay, type: :model do
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
      day_of_week: 1
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is invalid without day_of_week" do
      subject.day_of_week = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:day_of_week]).to include("can't be blank")
    end

    it "is invalid with day_of_week outside 0-6" do
      subject.day_of_week = 7
      expect(subject).not_to be_valid
      expect(subject.errors[:day_of_week]).to include("is not included in the list")
    end

    it "is invalid if day_of_week is not unique for a given flight_schedule" do
      subject.save!
      duplicate = described_class.new(
        flight_schedule: flight_schedule,
        day_of_week: 1
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:day_of_week]).to include("has already been taken")
    end
  end

  describe "associations" do
    it "belongs to flight_schedule" do
      assoc = described_class.reflect_on_association(:flight_schedule)
      expect(assoc.macro).to eq(:belongs_to)
    end
  end
end
