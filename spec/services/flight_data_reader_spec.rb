require 'rails_helper'

RSpec.describe FlightDataReader do
  describe ".search full coverage" do
    let(:test_data_path) { Rails.root.join("spec/fixtures/data/flight_full_coverage.txt") }

    before do
      FileUtils.mkdir_p(File.dirname(test_data_path))

      File.open(test_data_path, "w") do |f|
        f.puts "AI101,Air India,Delhi,Mumbai,2025-07-10,08:00,10:00,5"
        f.puts "AI102,Air India,Delhi,Mumbai,invalid-date,08:00,10:00,5"
        f.puts "AI103,Air India,Delhi,Mumbai,2025-07-10,08:00,10:00,0"
        f.puts "AI104,Air India,Delhi,Chennai,2025-07-10,08:00,10:00,5"
        f.puts "AI105,Air India,Delhi,Mumbai,2025-07-11,06:00,08:00,2"
        f.puts "AI106,Air India,Delhi,Mumbai,2025-07-10,05:00,07:00,1"
        f.puts "INVALID LINE WITHOUT ENOUGH FIELDS"
      end

      stub_const("#{described_class}::FLIGHT_DATA_PATH", test_data_path)
    end

    after do
      File.delete(test_data_path) if File.exist?(test_data_path)
    end

    context "when file does not exist" do
      it "returns empty array" do
        File.delete(test_data_path)
        expect(described_class.search("Delhi", "Mumbai")).to eq([])
      end
    end

    context "when departure_date param is invalid" do
      it "returns empty array" do
        result = described_class.search("Delhi", "Mumbai", "invalid-date")
        expect(result).to eq([])
      end
    end

    context "when searching without date" do
      it "returns all matching flights with seats" do
        result = described_class.search("Delhi", "Mumbai")
        expect(result.map { |f| f[:flight_number] }).to contain_exactly("AI101", "AI105", "AI106")
      end
    end

    context "when searching with date that matches" do
      it "returns only flights for that date" do
        result = described_class.search("Delhi", "Mumbai", "2025-07-10")
        expect(result.map { |f| f[:flight_number] }).to contain_exactly("AI101", "AI106")
      end
    end

    context "when searching with date that has no matching flights" do
      it "returns empty array" do
        result = described_class.search("Delhi", "Mumbai", "2025-07-12")
        expect(result).to eq([])
      end
    end

    context "when today flights are in past" do
      it "skips them" do
        allow(Date).to receive(:today).and_return(Date.parse("2025-07-10"))
        allow(Time).to receive(:now).and_return(Time.parse("09:00"))

        result = described_class.search("Delhi", "Mumbai", "2025-07-10")
        expect(result).to eq([])
      end
    end

    context "when today flights are yet to depart" do
      it "includes only future flights" do
        allow(Date).to receive(:today).and_return(Date.parse("2025-07-10"))
        allow(Time).to receive(:now).and_return(Time.parse("04:00"))

        result = described_class.search("Delhi", "Mumbai", "2025-07-10")
        expect(result.map { |f| f[:flight_number] }).to contain_exactly("AI101", "AI106")
      end
    end

    context "when source or destination do not match" do
      it "returns empty array" do
        result = described_class.search("Hyderabad", "Mumbai")
        expect(result).to eq([])
      end
    end

    context "when line has less than 8 fields" do
      it "skips invalid lines" do
        result = described_class.search("Delhi", "Mumbai")
        flight_numbers = result.map { |f| f[:flight_number] }
        expect(flight_numbers).not_to include("INVALID")
      end
    end
  end
end
