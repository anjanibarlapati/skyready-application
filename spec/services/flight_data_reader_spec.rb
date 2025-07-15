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

    it "returns flights for valid input" do
      result = described_class.search("Delhi", "Mumbai", Date.today, 1, "Economy")
      expect(result[:flights].map { |f| f[:flight_number] }).to include("AI202")
      expect(result[:found_route]).to be true
      expect(result[:found_date]).to be true
      expect(result[:seats_available]).to be true
    end

    it "returns empty flights for unmatched routes" do
      result = described_class.search("Delhi", "Chennai", Date.today, 1, "Economy")
      expect(result[:flights]).to be_empty
      expect(result[:found_route]).to be false
    end

    it "matches case-insensitively" do
      result = described_class.search("delhi", "mumbai", Date.today, 1, "Economy")
      expect(result[:flights].map { |f| f[:flight_number] }).to include("AI202")
    end

    it "excludes flights with invalid departure time" do
      append_test_flight "AI999,Air India,Delhi,Mumbai,#{Date.today + 2},99:99,#{Date.today + 2},13:00,100,85,50,40,20,20,#{base_price},6000,8000"
      result = described_class.search("Delhi", "Mumbai", Date.today + 2, 1, "Economy")
      expect(result[:flights].map { |f| f[:flight_number] }).not_to include("AI999")
    end

    it "skips invalid lines with incorrect field count" do
      append_test_flight "BROKEN,LINE,WITH,TOO,FEW,FIELDS"
      result = described_class.search("Delhi", "Mumbai", Date.today, 1, "Economy")
      expect(result[:flights].map { |f| f[:flight_number] }).not_to include("BROKEN")
    end

    it "excludes past flights for today's date" do
      past_time = (Time.now - 1.hour).strftime("%H:%M")
      append_test_flight "AI307,Air India,Delhi,Mumbai,#{Date.today},#{past_time},#{Date.today},14:00,100,80,50,40,20,20,#{base_price},6000,8000"
      result = described_class.search("Delhi", "Mumbai", Date.today, 1, "Economy")
      expect(result[:flights].map { |f| f[:flight_number] }).not_to include("AI307")
    end

    it "includes today's flights with future time" do
      future_time = (Time.now + 2.hours).strftime("%H:%M")
      append_test_flight "AI400,Air India,Delhi,Mumbai,#{Date.today},#{future_time},#{Date.today},14:00,100,80,50,40,20,20,#{base_price},6000,8000"
      result = described_class.search("Delhi", "Mumbai", Date.today, 1, "Economy")
      expect(result[:flights].map { |f| f[:flight_number] }).to include("AI400")
    end

    it "excludes flights if insufficient seats" do
      result = described_class.search("Delhi", "Mumbai", Date.today, 50, "Economy")
      expect(result[:flights]).to be_empty
      expect(result[:seats_available]).to be false
    end


    it "excludes flights with 0 total seats" do
      append_test_flight "AI999,Air India,Delhi,Mumbai,#{Date.today + 1},10:00,#{Date.today + 1},12:00,0,10,50,50,20,20,#{base_price},6000,8000"
      result = described_class.search("Delhi", "Mumbai", Date.today + 1, 1, "Economy")
      expect(result[:flights].map { |f| f[:flight_number] }).not_to include("AI999")
    end

    it "correctly calculates dynamic pricing with both multipliers" do
      append_test_flight "AI306,Air India,Delhi,Mumbai,#{Date.today + 2},10:00,#{Date.today + 2},12:00,100,60,50,40,20,20,#{base_price},6000,8000"
      result = described_class.search("Delhi", "Mumbai", Date.today + 2, 1, "Economy")
      flight = result[:flights].find { |f| f[:flight_number] == "AI306" }
      expect(flight[:price]).to eq(5600)
    end
    it "adds 35% for 50-75% booked" do
      append_test_flight "AI350,Air India,Delhi,Mumbai,#{Date.today + 2},12:00,#{Date.today + 2},14:00,100,40,50,40,20,20,#{base_price},6000,8000"
      result = described_class.search("Delhi", "Mumbai", Date.today + 2, 1, "Economy")
      flight = result[:flights].find { |f| f[:flight_number] == "AI350" }
      expect(flight[:price]).to eq(6200)
    end
    it "applies 2% date multiplier for 10 days before departure" do
      append_test_flight "AI410,Air India,Delhi,Mumbai,#{Date.today + 10},12:00,#{Date.today + 10},14:00,100,80,50,40,20,20,#{base_price},6000,8000"
      result = described_class.search("Delhi", "Mumbai", Date.today + 10, 1, "Economy")
      flight = result[:flights].find { |f| f[:flight_number] == "AI410" }
      expect(flight[:price]).to eq((base_price * 1.02).to_i)
    end

    it "applies 12% date multiplier for 5 days before departure" do
      append_test_flight "AI411,Air India,Delhi,Mumbai,#{Date.today + 5},12:00,#{Date.today + 5},14:00,100,80,50,40,20,20,#{base_price},6000,8000"
      result = described_class.search("Delhi", "Mumbai", Date.today + 5, 1, "Economy")
      flight = result[:flights].find { |f| f[:flight_number] == "AI411" }
      expect(flight[:price]).to eq((base_price * 1.12).to_i)
    end

    it "applies no date multiplier for flights more than 10 days away" do
      append_test_flight "AI999,Air India,Delhi,Mumbai,#{Date.today + 15},12:00,#{Date.today + 15},14:00,100,70,50,40,20,20,#{base_price},6000,8000"
      result = described_class.search("Delhi", "Mumbai", Date.today + 15, 1, "Economy")
      flight = result[:flights].find { |f| f[:flight_number] == "AI999" }
      expect(flight[:price]).to eq(base_price)
    end

    it "skips flight when flight_time subtraction raises ArgumentError" do
      append_test_flight "AI889,Air India,Delhi,Mumbai,#{Date.today + 1},12:00,#{Date.today + 1},14:00,100,80,50,40,20,20,#{base_price},6000,8000"

      allow_any_instance_of(Time).to receive(:-).and_raise(ArgumentError)

      result = described_class.search("Delhi", "Mumbai", Date.today + 1, 1, "Economy")
      expect(result[:flights].map { |f| f[:flight_number] }).not_to include("AI889")
    end
  end
end
