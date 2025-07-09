require 'rails_helper'
require 'active_support/testing/time_helpers'

RSpec.describe FlightDataReader do
  include ActiveSupport::Testing::TimeHelpers

  describe ".search" do
    let(:test_data_path) { Rails.root.join("spec/fixtures/data/flight_data.txt") }
    let(:base_price) { 4000 }

    around(:each) do |example|
      travel_to Time.new(2025, 7, 8, 10, 0, 0) do
        example.run
      end
    end


    before do
      FileUtils.mkdir_p(File.dirname(test_data_path))
      File.open(test_data_path, "w") do |f|
        f.puts [
          "AI202,Air India,Delhi,Mumbai,#{Date.today},18:00,#{Date.today},19:30,100,20,50,40,20,20,#{base_price},6000,8000",
          "AI203,Air India,Delhi,Mumbai,#{Date.today + 3},18:00,#{Date.today + 3},20:30,100,20,50,10,20,9,#{base_price},6000,8000",
          "AI204,Air India,Delhi,Mumbai,#{Date.today + 3},23:00,#{Date.today + 4},08:30,100,14,50,8,20,6,#{base_price},6000,8000",
          "6E501,IndiGo,Mumbai,Goa,#{Date.today + 3},09:15,#{Date.today + 3},11:00,100,0,50,0,20,0,3000,4500,6000",
          "SG403,SpiceJet,Bengaluru,Delhi,#{Date.today + 4},14:00,#{Date.today + 4},16:45,100,4,50,2,20,2,5000,7500,10000"
        ].join("\n")
      end

      stub_const("#{described_class}::FLIGHT_DATA_PATH", test_data_path)
    end

    after { File.delete(test_data_path) if File.exist?(test_data_path) }

    def append_test_flight(line)
      File.open(test_data_path, "a") { |f| f.puts line }
    end


    describe "basic functionality" do
      it "returns flights for valid input" do
        result = described_class.search("Delhi", "Mumbai", Date.today.to_s)
        expect(result.map { |f| f[:flight_number] }).to include("AI202")
      end

      it "returns empty array for unmatched routes" do
        expect(described_class.search("Delhi", "Chennai")).to be_empty
      end

      it "matches case-insensitively" do
        result = described_class.search("delhi", "mumbai", Date.today.to_s)
        expect(result.map { |f| f[:flight_number] }).to include("AI202")
      end

      it "returns flights when date not passed" do
        result = described_class.search("Delhi", "Mumbai")
        expect(result.all? { |f| f[:source] == "Delhi" && f[:destination] == "Mumbai" }).to be true
      end

      it "excludes flights with invalid departure time" do
        append_test_flight "AI999,Air India,Delhi,Mumbai,#{Date.today + 2},99:99,#{Date.today + 2},13:00,100,85,50,40,20,20,140,4000,6000,8000"
        result = described_class.search("Delhi", "Mumbai", (Date.today + 2).to_s)
        expect(result.map { |f| f[:flight_number] }).not_to include("AI999")
      end

      it "skips invalid lines with incorrect field count" do
        append_test_flight "BROKEN,LINE,WITH,TOO,FEW,FIELDS"
        result = described_class.search("Delhi", "Mumbai")
        expect(result.map { |f| f[:flight_number] }).not_to include("BROKEN")
      end

      it "excludes past flights for today's date" do
        past_time = (Time.now - 1.hour).strftime("%H:%M")
        append_test_flight "AI307,Air India,Delhi,Mumbai,#{Date.today},#{past_time},#{Date.today},14:00,100,80,50,40,20,20,#{base_price},6000,8000"
        result = described_class.search("Delhi", "Mumbai", Date.today.to_s)
        expect(result.map { |f| f[:flight_number] }).not_to include("AI307")
      end

      it "includes today's flights with future time" do
        future_time = (Time.now + 2.hours).strftime("%H:%M")
        append_test_flight "AI400,Air India,Delhi,Mumbai,#{Date.today},#{future_time},#{Date.today},14:00,100,80,50,40,20,20,#{base_price},6000,8000"
        result = described_class.search("Delhi", "Mumbai", Date.today.to_s)
        expect(result.map { |f| f[:flight_number] }).to include("AI400")
      end

      it "handles invalid departure_date format gracefully" do
        result = described_class.search("Delhi", "Mumbai", "invalid-date")
        expect(result.map { |f| f[:flight_number] }).to include("AI202")
      end
    end

    describe "traveller count logic" do
      it "defaults to 1 for invalid counts" do
        ["", nil, "abc", -5].each do |count|
          expect(described_class.search("Delhi", "Mumbai", Date.today.to_s, count)).not_to be_empty
        end
      end

      it "excludes flights if insufficient seats" do
        result = described_class.search("Delhi", "Mumbai", Date.today.to_s, 50)
        expect(result).to be_empty
      end
    end

    describe "class type validations" do
      it "defaults to Economic if blank or nil" do
        [nil, ""].each do |ctype|
          result = described_class.search("Delhi", "Mumbai", Date.today.to_s, 1, ctype)
          expect(result.map { |f| f[:flight_number] }).to include("AI202")
        end
      end

      it "excludes unknown class types" do
        result = described_class.search("Delhi", "Mumbai", Date.today.to_s, 1, "Luxury")
        expect(result).to be_empty
      end

      it "excludes flights with 0 total seats" do
        append_test_flight "AI999,Air India,Delhi,Mumbai,#{Date.today + 1},10:00,#{Date.today + 1},12:00,0,10,50,50,20,20,#{base_price},6000,8000"
        result = described_class.search("Delhi", "Mumbai", (Date.today + 1).to_s)
        expect(result.map { |f| f[:flight_number] }).not_to include("AI999")
      end
    end

    describe "pricing strategy" do
      it "applies base price for <=30% booked" do
        append_test_flight "AI301,Air India,Delhi,Mumbai,#{Date.today + 2},12:00,#{Date.today + 2},14:00,100,80,50,40,20,20,#{base_price},6000,8000"
        result = described_class.search("Delhi", "Mumbai", (Date.today + 2).to_s)
        flight = result.find { |f| f[:flight_number] == "AI301" }
        expect(flight[:price]).to eq(4800)
      end

      it "adds 20% for 30-50% booked" do
        append_test_flight "AI302,Air India,Delhi,Mumbai,#{Date.today + 2},12:00,#{Date.today + 2},14:00,100,60,50,40,20,20,#{base_price},6000,8000"
        result = described_class.search("Delhi", "Mumbai", (Date.today + 2).to_s)
        flight = result.find { |f| f[:flight_number] == "AI302" }
        expect(flight[:price]).to eq(5600)
      end

      it "adds 35% for 50-75% booked" do
        append_test_flight "AI303,Air India,Delhi,Mumbai,#{Date.today + 2},12:00,#{Date.today + 2},14:00,100,30,50,40,20,20,#{base_price},6000,8000"
        result = described_class.search("Delhi", "Mumbai", (Date.today + 2).to_s)
        flight = result.find { |f| f[:flight_number] == "AI303" }
        expect(flight[:price]).to eq(6200)
      end

      it "adds 50% for >75% booked" do
        append_test_flight "AI304,Air India,Delhi,Mumbai,#{Date.today + 2},12:00,#{Date.today + 2},14:00,100,10,50,40,20,20,#{base_price},6000,8000"
        result = described_class.search("Delhi", "Mumbai", (Date.today + 2).to_s)
        flight = result.find { |f| f[:flight_number] == "AI304" }
        expect(flight[:price]).to eq(6800)
      end

      it "applies only date multiplier for >10 days away" do
        append_test_flight "AI305,Air India,Delhi,Mumbai,#{Date.today + 15},12:00,#{Date.today + 15},14:00,100,80,50,40,20,20,#{base_price},6000,8000"
        result = described_class.search("Delhi", "Mumbai", (Date.today + 15).to_s)
        flight = result.find { |f| f[:flight_number] == "AI305" }
        expect(flight[:price]).to eq(base_price)
      end

      it "applies both multipliers together" do
        append_test_flight "AI306,Air India,Delhi,Mumbai,#{Date.today + 2},10:00,#{Date.today + 2},12:00,100,60,50,40,20,20,#{base_price},6000,8000"
        result = described_class.search("Delhi", "Mumbai", (Date.today + 2).to_s)
        flight = result.find { |f| f[:flight_number] == "AI306" }
        expect(flight[:price]).to eq(5600)
      end
    end
  end
end
