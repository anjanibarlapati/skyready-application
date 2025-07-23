require 'rails_helper'

RSpec.describe Airline, type: :model do
  subject { described_class.new(name: "TestAir") }

  describe "validations" do
    it "is valid with a unique name" do
      expect(subject).to be_valid
    end

    it "is invalid without a name" do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it "is invalid with a duplicate name" do
      described_class.create!(name: "TestAir")
      duplicate = described_class.new(name: "TestAir")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end

  describe "associations" do
    it "has many flight_routes" do
      assoc = described_class.reflect_on_association(:flight_routes)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end
  end
end
