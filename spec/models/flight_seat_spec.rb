require 'rails_helper'

RSpec.describe FlightSeat, type: :model do
  describe "associations" do
    it { should belong_to(:flight_schedule) }
  end

  describe "validations" do
    subject { build(:flight_seat) }

    it { should validate_presence_of(:class_type) }
    it { should validate_inclusion_of(:class_type).in_array(FlightSeat::CLASS_TYPES) }

    it { should validate_presence_of(:total_seats) }
    it { should validate_numericality_of(:total_seats).only_integer.is_greater_than_or_equal_to(0) }

    it { should validate_presence_of(:base_price) }
    it { should validate_numericality_of(:base_price).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "valid factory" do
    it "is valid with correct attributes" do
      expect(build(:flight_seat)).to be_valid
    end
  end
end
