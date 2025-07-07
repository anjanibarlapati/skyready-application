require 'rails_helper'

RSpec.describe FlightDataReader do
  describe ".search" do
    let(:test_data_path) { Rails.root.join("spec/fixtures/data/test_data.txt") }

    before do
      FileUtils.mkdir_p(File.dirname(test_data_path))

      File.open(test_data_path, "w") do |f|
        f.puts "SK001,Air India,Delhi,Mumbai,2025-07-10,08:00,10:00"
        f.puts "SK002,IndiGo,Hyderabad,Chennai,2025-07-11,09:00,11:00"
        f.puts "SK003,SpiceJet,Delhi,Chennai,invalid-date,14:00,16:00"
        f.puts "SK004,Air India,Goa,Delhi,2025-07-11,07:00,09:00"
      end

      stub_const("#{described_class}::FLIGHT_DATA_PATH", test_data_path)
    end

    after do
      File.delete(test_data_path) if File.exist?(test_data_path)
    end

    it "returns matching flights for source and destination without date" do
      result = described_class.search("Delhi", "Mumbai")

      expect(result).to match_array([
        {
          flight_number: "SK001",
          airline_name: "Air India",
          source: "Delhi",
          destination: "Mumbai",
          departure_date: "2025-07-10",
          departure_time: "08:00",
          arrival_time: "10:00"
        }
      ])
    end

    it "returns matching flights for source, destination, and valid date" do
      result = described_class.search("Delhi", "Mumbai", "2025-07-10")

      expect(result.size).to eq(1)
      expect(result.first[:flight_number]).to eq("SK001")
    end

    it "returns empty array when date does not match" do
      result = described_class.search("Delhi", "Mumbai", "2025-07-11")
      expect(result).to eq([])
    end

    it "skips flights with invalid date format in file" do
      result = described_class.search("Delhi", "Chennai")
      expect(result).to eq([])
    end

    it "skips already departed flights for today if date matches today" do
      allow(Date).to receive(:today).and_return(Date.parse("2025-07-11"))
      allow(Time).to receive(:now).and_return(Time.parse("08:00"))

      result = described_class.search("Goa", "Delhi", "2025-07-11")

      expect(result).to eq([])
    end

    it "includes flights for today that are yet to depart" do
      allow(Date).to receive(:today).and_return(Date.parse("2025-07-11"))
      allow(Time).to receive(:now).and_return(Time.parse("06:00"))

      result = described_class.search("Goa", "Delhi", "2025-07-11")

      expect(result.size).to eq(1)
      expect(result.first[:flight_number]).to eq("SK004")
    end

    it "returns empty array if file does not exist" do
      File.delete(test_data_path)
      expect(described_class.search("Delhi", "Mumbai")).to eq([])
    end

    it "returns empty array for invalid departure_date param" do
      result = described_class.search("Delhi", "Mumbai", "invalid-date")
      expect(result).to eq([])
    end
  end
end
