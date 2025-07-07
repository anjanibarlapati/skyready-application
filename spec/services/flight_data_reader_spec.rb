require 'rails_helper'

RSpec.describe FlightDataReader do
  describe ".search" do
    let(:data_path) { Rails.root.join("app/assets/data/data.txt") }

    before do
      FileUtils.mkdir_p(File.dirname(data_path))

      File.open(data_path, "w") do |f|
        f.puts "SK001,Delhi,Mumbai"
        f.puts "SK002,Hyderabad,Chennai"
        f.puts "SK003,Delhi,Chennai"
        f.puts "SK004,Goa,Delhi"
      end
    end

    after do
      File.delete(data_path) if File.exist?(data_path)
    end

    it "returns matching flights for given source and destination (case-insensitive)" do
      result = described_class.search("delhi", "mumbai")

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first).to eq({
        flight_number: "SK001",
        source: "Delhi",
        destination: "Mumbai"
      })
    end

    it "returns empty array if no match found" do
      result = described_class.search("Pune", "Bengaluru")
      expect(result).to eq([])
    end

    it "returns empty array if file does not exist" do
      File.delete(data_path)
      expect(described_class.search("Delhi", "Mumbai")).to eq([])
    end
  end
end
