require 'rails_helper'

RSpec.describe FlightDataUpdater do
  let(:test_data_path) { Rails.root.join("spec/fixtures/data/flight_data_updater.txt") }
  let(:original_lines) do
    [
      "AI202,Air India,Delhi,Mumbai,2025-07-15,10:00,2025-07-15,12:00,100,10,50,20,20,15,4000,6000,8000",
      "AI203,Air India,Delhi,Mumbai,2025-07-16,13:00,2025-07-16,15:00,100,5,50,10,20,10,4000,6000,8000",
      "LINE,WITH,FEW,FIELDS"
    ]
  end

  before do
    FileUtils.mkdir_p(File.dirname(test_data_path))
    File.open(test_data_path, "w") { |f| f.puts original_lines }
    stub_const("#{described_class}::FLIGHT_DATA_PATH", test_data_path)
  end

  after do
    FileUtils.rm_f(test_data_path)
    FileUtils.rm_f("#{test_data_path}.tmp")
  end

  def read_fields(index = 0)
    File.readlines(test_data_path)[index].strip.split(",")
  end

  shared_examples "seat reducer" do |class_type, class_index, initial|
    it "reduces #{class_type} seats and returns true" do
      result = described_class.reduce_seats("AI202", DateTime.parse("2025-07-15 10:00"), class_type, 5)

      expect(result).to be true
      fields = read_fields
      expect(fields[class_index].to_i).to eq([ initial - 5, 0 ].max)
    end
  end

  describe ".reduce_seats" do
    include_examples "seat reducer", "Economy", 9, 10
    include_examples "seat reducer", "Second Class", 11, 20
    include_examples "seat reducer", "First Class", 13, 15

    it "does not reduce or update if seats are insufficient and returns false" do
      result = described_class.reduce_seats("AI202", DateTime.parse("2025-07-15 10:00"), "Economy", 50)

      expect(result).to be false
      fields = read_fields
      expect(fields[9].to_i).to eq(10)
    end

    it "returns false if file doesn't exist" do
      stub_const("#{described_class}::FLIGHT_DATA_PATH", Rails.root.join("nonexistent.txt"))
      result = nil

      expect {
        result = described_class.reduce_seats("AI202", DateTime.parse("2025-07-15 10:00"), "Economy", 1)
      }.not_to raise_error

      expect(result).to be false
    end

    it "returns false and leaves file unchanged if flight number or date does not match" do
      result = described_class.reduce_seats("WRONG", DateTime.parse("2025-07-15 10:00"), "Economy", 1)

      expect(result).to be false
      expect(File.readlines(test_data_path).map(&:strip)).to eq(original_lines)
    end

    it "returns true and skips invalid lines while processing valid ones" do
      result = described_class.reduce_seats("AI202", DateTime.parse("2025-07-15 10:00"), "Economy", 1)

      expect(result).to be true
      expect(read_fields[9].to_i).to eq(9)
    end

    it "rewrites the updated line correctly in the output file" do
      result = described_class.reduce_seats("AI202", DateTime.parse("2025-07-15 10:00"), "Economy", 3)

      expect(result).to be true
      updated_line = File.readlines(test_data_path).first.strip
      fields = updated_line.split(",")

      expect(fields[0]).to eq("AI202")
      expect(fields[4]).to eq("2025-07-15")
      expect(fields[9].to_i).to eq(7)
      expect(updated_line).to eq("AI202,Air India,Delhi,Mumbai,2025-07-15,10:00,2025-07-15,12:00,100,7,50,20,20,15,4000,6000,8000")
    end

    it "returns false when class_type is invalid (hits else case with available = 0)" do
      result = described_class.reduce_seats("AI202", DateTime.parse("2025-07-15 10:00"), "Business", 1)

      expect(result).to be false
      current_lines = File.readlines(test_data_path).map(&:strip)
      expect(current_lines).to eq(original_lines)
    end

    it "removes the temp file after successful update" do
      described_class.reduce_seats("AI202", DateTime.parse("2025-07-15 10:00"), "Economy", 1)
      expect(File.exist?("#{test_data_path}.tmp")).to be false
    end

    it "cleans up temp file if an error occurs during write" do
      allow(FileUtils).to receive(:mv).and_raise(StandardError.new("simulated move error"))

      result = described_class.reduce_seats("AI202", DateTime.parse("2025-07-15 10:00"), "Economy", 1)

      expect(result).to be false
      expect(File.exist?("#{test_data_path}.tmp")).to be false
    end
  end
end
