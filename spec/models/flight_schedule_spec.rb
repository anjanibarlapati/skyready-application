require 'rails_helper'

RSpec.describe FlightSchedule, type: :model do
  describe "associations" do
    it { should belong_to(:flight_route) }
    it { should have_many(:bookings).dependent(:destroy) }
    it { should have_many(:flight_seats).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:flight_schedule) }

    it { should validate_presence_of(:departure_time) }
    it { should validate_presence_of(:arrival_time) }
    it { should validate_presence_of(:start_date) }

    context "when recurring is true" do
      it "validates presence of days_of_week" do
        schedule = build(:flight_schedule, recurring: true, days_of_week: nil)
        expect(schedule).not_to be_valid
        expect(schedule.errors[:days_of_week]).to include("can't be blank")
      end
    end

    context "custom validation: end_date_after_start_date" do
      it "adds error if end_date is before start_date" do
        schedule = build(:flight_schedule,
                         start_date: Date.today,
                         end_date: Date.yesterday)
        expect(schedule).not_to be_valid
        expect(schedule.errors[:end_date]).to include("must be after start_date")
      end

      it "passes if end_date is after start_date" do
        schedule = build(:flight_schedule,
                         start_date: Date.today,
                         end_date: Date.tomorrow)
        expect(schedule).to be_valid
      end
    end

    context "custom validation: days_of_week_valid" do
      it "adds error if days_of_week contains invalid values" do
        schedule = build(:flight_schedule, days_of_week: [ 0, 1, 8 ])
        expect(schedule).not_to be_valid
        expect(schedule.errors[:days_of_week]).to include("must contain values between 0 (Sunday) and 6 (Saturday)")
      end

      it "passes if all days_of_week are valid" do
        schedule = build(:flight_schedule, days_of_week: [ 0, 1, 2, 3, 4, 5, 6 ])
        expect(schedule).to be_valid
      end
    end
  end

  describe "valid factory" do
    it "is valid with correct attributes" do
      expect(build(:flight_schedule)).to be_valid
    end
  end
end
