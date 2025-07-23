require 'rails_helper'

RSpec.describe FlightRoute, type: :model do
  let(:airline) { Airline.create!(name: "TestAir") }

  subject do
    described_class.new(
      airline: airline,
      source: "DEL",
      destination: "BOM"
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is invalid without a source" do
      subject.source = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:source]).to include("can't be blank")
    end

    it "is invalid without a destination" do
      subject.destination = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:destination]).to include("can't be blank")
    end

    it "is invalid with duplicate airline + source + destination" do
      described_class.create!(
        airline: airline,
        source: "DEL",
        destination: "BOM"
      )

      duplicate = described_class.new(
        airline: airline,
        source: "DEL",
        destination: "BOM"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:airline_id]).to include("already has a route between this source and destination")
    end

    it "allows same source-destination for different airlines" do
      another_airline = Airline.create!(name: "OtherAir")
      described_class.create!(
        airline: airline,
        source: "DEL",
        destination: "BOM"
      )

      new_route = described_class.new(
        airline: another_airline,
        source: "DEL",
        destination: "BOM"
      )

      expect(new_route).to be_valid
    end
  end

  describe "associations" do
    it "belongs to airline" do
      assoc = described_class.reflect_on_association(:airline)
      expect(assoc.macro).to eq(:belongs_to)
    end

    it "has many flights with dependent: :destroy" do
      assoc = described_class.reflect_on_association(:flights)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end
  end
end
