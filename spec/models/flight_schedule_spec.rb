require 'rails_helper'

RSpec.describe FlightSchedule, type: :model do
  let(:airline) { Airline.create!(name: "TestAir") }
  let(:flight_route) { FlightRoute.create!(airline: airline, source: "DEL", destination: "BOM") }
  let(:flight) { Flight.create!(flight_number: "TA123", flight_route: flight_route) }

  let(:valid_attributes) do
    {
      flight: flight,
      departure_time: Time.zone.parse("10:00"),
      arrival_time: Time.zone.parse("12:00"),
      start_date: Date.today,
      end_date: nil,
      recurring: true
    }
  end

  subject { described_class.new(valid_attributes) }

  describe "validations" do
    it "is valid with all attributes" do
      expect(subject).to be_valid
    end

    it "is invalid without departure_time" do
      subject.departure_time = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:departure_time]).to include("can't be blank")
    end

    it "is invalid without arrival_time" do
      subject.arrival_time = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:arrival_time]).to include("can't be blank")
    end

    it "is invalid without start_date" do
      subject.start_date = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:start_date]).to include("can't be blank")
    end

    it "is invalid if recurring is nil" do
      subject.recurring = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:recurring]).to include("is not included in the list")
    end

    it "is valid if arrival_time is before departure_time but end_date is next day" do
      subject.departure_time = Time.zone.parse("22:00")
      subject.arrival_time = Time.zone.parse("01:00")
      subject.end_date = subject.start_date + 1

      expect(subject).to be_valid
    end

    it "is invalid if overlapping time slot exists" do
      described_class.create!(valid_attributes)

      overlapping = described_class.new(valid_attributes.merge(
        departure_time: Time.zone.parse("11:00"),
        arrival_time: Time.zone.parse("13:00")
      ))

      expect(overlapping).not_to be_valid
      expect(overlapping.errors[:base]).to include("Flight schedule overlaps with an existing schedule for this flight")
    end

    it "is invalid with duplicate time + dates + flight" do
      described_class.create!(valid_attributes)

      duplicate = described_class.new(valid_attributes)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:departure_time]).to include("with same time and dates already exists for this flight")
    end
  end

  describe "associations" do
    it "belongs to flight" do
      assoc = described_class.reflect_on_association(:flight)
      expect(assoc.macro).to eq(:belongs_to)
    end

    it "has many flight_schedule_days with dependent: :destroy" do
      assoc = described_class.reflect_on_association(:flight_schedule_days)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end

    it "has many flight_seats with dependent: :destroy" do
      assoc = described_class.reflect_on_association(:flight_seats)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end

    it "has many bookings with dependent: :destroy" do
      assoc = described_class.reflect_on_association(:bookings)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end
  end
end
