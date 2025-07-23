require 'rails_helper'

RSpec.describe Flight, type: :model do
  let(:airline) { Airline.create!(name: "Test Airline") }
  let(:flight_route) do
    FlightRoute.create!(
      airline: airline,
      source: "DEL",
      destination: "BOM"
    )
  end

  subject do
    described_class.new(
      flight_number: "TA123",
      flight_route: flight_route
    )
  end

  describe "validations" do
    it "is valid with a flight_number and flight_route" do
      expect(subject).to be_valid
    end

    it "is invalid without a flight_number" do
      subject.flight_number = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:flight_number]).to include("can't be blank")
    end

    it "is invalid with a duplicate flight_number" do
      subject.save!
      duplicate = described_class.new(
        flight_number: "TA123",
        flight_route: flight_route
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:flight_number]).to include("has already been taken")
    end
  end

  describe "associations" do
    it "belongs to flight_route" do
      assoc = described_class.reflect_on_association(:flight_route)
      expect(assoc.macro).to eq(:belongs_to)
    end

    it "has one airline through flight_route" do
      assoc = described_class.reflect_on_association(:airline)
      expect(assoc.macro).to eq(:has_one)
      expect(assoc.options[:through]).to eq(:flight_route)
    end

    it "has many flight_schedules with dependent: :destroy" do
      assoc = described_class.reflect_on_association(:flight_schedules)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end
  end
end
