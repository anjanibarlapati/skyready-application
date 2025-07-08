require 'rails_helper'

RSpec.describe FlightDataReader do
  describe ".search with parameters: source, destination, date, class_type, travellers_count" do
    let(:test_data_path) { Rails.root.join("spec/fixtures/data/flight_data.txt") }

    before do
      FileUtils.mkdir_p(File.dirname(test_data_path))
      File.open(test_data_path, "w") do |f|
        f.puts "AI202,Air India,Delhi,Mumbai,2025-07-08,18:00,2025-07-08,19:30,100,20,50,40,20,20,140,4000,6000,8000"
        f.puts "AI203,Air India,Delhi,Mumbai,2025-07-11,18:00,2025-07-11,20:30,100,20,50,10,20,9,39,4000,6000,8000"
        f.puts "AI202,Air India,Delhi,Mumbai,2025-07-11,11:00,2025-07-12,08:30,100,14,50,8,20,6,28,4000,6000,8000"
        f.puts "6E501,IndiGo,Mumbai,Goa,2025-07-11,09:15,2025-07-11,11:00,100,0,50,0,20,0,0,3000,4500,6000"
        f.puts "SG403,SpiceJet,Bengaluru,Delhi,2025-07-12,14:00,2025-07-12,16:45,100,4,50,2,20,2,8,5000,7500,10000"
      end

      stub_const("#{described_class}::FLIGHT_DATA_PATH", test_data_path)
    end

    after do
      File.delete(test_data_path) if File.exist?(test_data_path)
    end

    context "basic functionality" do
      it "returns matching flights for valid inputs" do
        result = described_class.search("Delhi", "Mumbai", "2025-07-08")
        expect(result.map { |f| f[:flight_number] }).to include("AI202")
      end

      it "returns empty if no matching flights" do
        result = described_class.search("Delhi", "Chennai")
        expect(result).to be_empty
      end

      it "is case-insensitive for source and destination" do
        result = described_class.search("delhi", "mumbai", "2025-07-08")
        expect(result.map { |f| f[:flight_number] }).to include("AI202")
      end
    end

    context "traveller count validations" do
      it "defaults to 1 if not provided or invalid" do
        [ "", nil, "abc", -3 ].each do |tc|
          result = described_class.search("Delhi", "Mumbai", "2025-07-08", tc, "Economic")
          expect(result).not_to be_empty
        end
      end

      it "filters flights if travellers_count exceeds available seats" do
        result = described_class.search("Delhi", "Mumbai", "2025-07-08", 50, "Economic")
        expect(result).to be_empty
      end
    end

    context "class type validations" do
      it "defaults to Economic if blank or nil" do
        [ nil, "" ].each do |ctype|
          result = described_class.search("Delhi", "Mumbai", "2025-07-08", 1, ctype)
          expect(result.map { |f| f[:flight_number] }).to include("AI202")
        end
      end

      it "returns empty if class_type is invalid" do
        result = described_class.search("Delhi", "Mumbai", "2025-07-08", 1, "Luxury Class")
        expect(result).to be_empty
      end
    end

    context "pricing strategy" do
      def append_test_flight(line)
        File.open(test_data_path, "a") { |f| f.puts line }
      end

      it "calculates correct base price for <=30% booked" do
        append_test_flight "AI301,Air India,Delhi,Mumbai,2025-07-10,12:00,2025-07-10,14:00,100,80,50,40,20,20,140,4000,6000,8000"
        result = described_class.search("Delhi", "Mumbai", "2025-07-10", 1, "Economic")
        flight = result.find { |f| f[:flight_number] == "AI301" }
        expect(flight[:price]).to eq(4000)
      end

      it "adds 20% for 30-50% booked" do
        append_test_flight "AI302,Air India,Delhi,Mumbai,2025-07-10,15:00,2025-07-10,17:00,100,60,50,40,20,20,140,4000,6000,8000"
        result = described_class.search("Delhi", "Mumbai", "2025-07-10", 1, "Economic")
        flight = result.find { |f| f[:flight_number] == "AI302" }
        expect(flight[:price]).to eq((4000 * 1.2).to_i)
      end

      it "adds 35% for 50-75% booked" do
        append_test_flight "AI303,Air India,Delhi,Mumbai,2025-07-10,18:00,2025-07-10,20:00,100,40,50,40,20,20,140,4000,6000,8000"
        result = described_class.search("Delhi", "Mumbai", "2025-07-10", 1, "Economic")
        flight = result.find { |f| f[:flight_number] == "AI303" }
        expect(flight[:price]).to eq((4000 * 1.35).to_i)
      end

      it "adds 50% for >75% booked" do
        append_test_flight "AI304,Air India,Delhi,Mumbai,2025-07-10,21:00,2025-07-10,23:00,100,10,50,40,20,20,140,4000,6000,8000"
        result = described_class.search("Delhi", "Mumbai", "2025-07-10", 1, "Economic")
        flight = result.find { |f| f[:flight_number] == "AI304" }
        expect(flight[:price]).to eq((4000 * 1.5).to_i)
      end
    end

    context "arrival date difference" do
      it "returns +1 or +2 for next day arrivals" do
        result = described_class.search("Delhi", "Mumbai")
        flight = result.find { |f| f[:flight_number] == "AI202" }
        expect(flight[:arrival_date_difference]).to eq(nil)

        flight2 = result.find { |f| f[:flight_number] == "AI202" && f[:arrival_date] == "2025-07-12" }
        expect(flight2[:arrival_date_difference]).to eq("+1")
      end
    end
  end
end
