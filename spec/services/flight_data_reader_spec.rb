require 'rails_helper'

RSpec.describe FlightDataReader do
  describe ".search full coverage with date difference" do
    let(:test_data_path) { Rails.root.join("spec/fixtures/data/flight_date_diff.txt") }

    before do
      FileUtils.mkdir_p(File.dirname(test_data_path))

      File.open(test_data_path, "w") do |f|
        f.puts "AI101,Air India,Delhi,Mumbai,2025-07-10,08:00,2025-07-10,10:00,5"
        f.puts "AI102,Air India,Delhi,Mumbai,2025-07-10,23:30,2025-07-11,01:30,4"
        f.puts "AI103,Air India,Delhi,Mumbai,2025-07-10,23:45,2025-07-12,01:15,3"
        f.puts "AI104,Air India,Delhi,Mumbai,invalid-date,08:00,2025-07-10,10:00,5"
        f.puts "AI105,Air India,Delhi,Mumbai,2025-07-10,08:00,invalid-date,10:00,5"
        f.puts "AI106,Air India,Delhi,Mumbai,2025-07-10,08:00,2025-07-10,10:00,0"
        f.puts "AI107,Air India,Delhi,Chennai,2025-07-10,08:00,2025-07-10,10:00,5"
        f.puts "AI108,Air India,Delhi,Mumbai,2025-07-11,05:00,2025-07-11,07:00,2"
        f.puts "AI109,Air India,Delhi,Mumbai,2025-07-11,20:00,2025-07-11,22:00,2"
        f.puts "INVALID LINE WITHOUT ENOUGH FIELDS"
      end

      stub_const("#{described_class}::FLIGHT_DATA_PATH", test_data_path)
    end

    after do
      File.delete(test_data_path) if File.exist?(test_data_path)
    end

    it "returns empty array if file does not exist" do
      File.delete(test_data_path)
      expect(described_class.search("Delhi", "Mumbai")).to eq([])
    end

    it "returns empty array for invalid departure_date param" do
      result = described_class.search("Delhi", "Mumbai", "invalid-date")
      expect(result).to eq([])
    end

    it "returns all matching flights without departure_date param" do
      result = described_class.search("Delhi", "Mumbai")
      expect(result.map { |f| f[:flight_number] }).to contain_exactly("AI101", "AI102", "AI103", "AI108", "AI109")
    end

    it "returns only flights for a given date" do
      result = described_class.search("Delhi", "Mumbai", "2025-07-10")
      expect(result.map { |f| f[:flight_number] }).to contain_exactly("AI101", "AI102", "AI103")
    end

    it "skips flights with invalid departure or arrival date in file" do
      result = described_class.search("Delhi", "Mumbai")
      flight_numbers = result.map { |f| f[:flight_number] }
      expect(flight_numbers).not_to include("AI104", "AI105")
    end

    it "skips flights with zero seats" do
      result = described_class.search("Delhi", "Mumbai")
      expect(result.map { |f| f[:flight_number] }).not_to include("AI106")
    end

    it "skips flights with different route" do
      result = described_class.search("Delhi", "Mumbai")
      expect(result.map { |f| f[:flight_number] }).not_to include("AI107")
    end

    it "skips lines with insufficient fields" do
      result = described_class.search("Delhi", "Mumbai")
      expect(result.map { |f| f[:flight_number] }).not_to include("INVALID")
    end

    it "skips today flights that have already departed" do
      allow(Date).to receive(:today).and_return(Date.parse("2025-07-11"))
      allow(Time).to receive(:now).and_return(Time.parse("06:00"))

      result = described_class.search("Delhi", "Mumbai", "2025-07-11")
      expect(result.map { |f| f[:flight_number] }).to contain_exactly("AI109")
    end

    it "includes today flights that are yet to depart" do
      allow(Date).to receive(:today).and_return(Date.parse("2025-07-11"))
      allow(Time).to receive(:now).and_return(Time.parse("19:00"))

      result = described_class.search("Delhi", "Mumbai", "2025-07-11")
      expect(result.map { |f| f[:flight_number] }).to contain_exactly("AI109")
    end

    it "returns empty array for flights with only arrival date matching" do
      result = described_class.search("Delhi", "Mumbai", "2025-07-12")
      expect(result).to eq([])
    end

    it "correctly sets arrival_date_difference field for +1 and +2 days" do
      result = described_class.search("Delhi", "Mumbai")
      flight1 = result.find { |f| f[:flight_number] == "AI102" }
      flight2 = result.find { |f| f[:flight_number] == "AI103" }
      flight3 = result.find { |f| f[:flight_number] == "AI101" }

      expect(flight1[:arrival_date_difference]).to eq("+1")
      expect(flight2[:arrival_date_difference]).to eq("+2")
      expect(flight3[:arrival_date_difference]).to be_nil
    end

    it "skips flights if available seats are less than travellers_count" do
  result = described_class.search("Delhi", "Mumbai", nil, 6)
  expect(result.map { |f| f[:flight_number] }).not_to include("AI101", "AI102", "AI103")
end

it "includes flights with exact matching seats to travellers_count" do
  result = described_class.search("Delhi", "Mumbai", nil, 5)
  expect(result.map { |f| f[:flight_number] }).to include("AI101")
end

it "defaults travellers_count to 1 if not provided" do
  result = described_class.search("Delhi", "Mumbai")
  expect(result).not_to be_empty
end

it "treats blank travellers_count as 1" do
  result = described_class.search("Delhi", "Mumbai", nil, "")
  expect(result).not_to be_empty
end

it "treats invalid (non-integer) travellers_count as 1" do
  result = described_class.search("Delhi", "Mumbai", nil, "abc")
  expect(result).not_to be_empty
end

it "matches source and destination case-insensitively" do
  result = described_class.search("delhi", "mumbai")
  expect(result.map { |f| f[:flight_number] }).to include("AI101", "AI102", "AI103")
end
  end
end
