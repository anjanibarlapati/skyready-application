require 'rails_helper'

RSpec.describe FlightDataUpdater do
  let(:test_data_path) { Rails.root.join("spec/fixtures/data/flight_data_updater.txt") }
  let(:original_lines) do
    [
      "AI202,Air India,Delhi,Mumbai,2025-07-15,10:00,2025-07-15,12:00,100,10,50,20,20,15,100,4000,6000,8000",
      "AI203,Air India,Delhi,Mumbai,2025-07-16,13:00,2025-07-16,15:00,100,5,50,10,20,10,80,4000,6000,8000",
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
    it "reduces #{class_type} seats and total seats correctly" do
      described_class.reduce_seats("AI202", "2025-07-15", class_type, 5)

      fields = read_fields
      expect(fields[class_index].to_i).to eq([initial - 5, 0].max)
      expect(fields[14].to_i).to eq(95)
    end
  end

  describe ".reduce_seats" do
    include_examples "seat reducer", "Economic", 9, 10
    include_examples "seat reducer", "Second Class", 11, 20
    include_examples "seat reducer", "First Class", 13, 15

    it "does not reduce below 0 seats" do
      described_class.reduce_seats("AI202", "2025-07-15", "Economic", 50)

      fields = read_fields
      expect(fields[9].to_i).to eq(0)
      expect(fields[14].to_i).to eq(50)
    end

    it "does nothing if file doesn't exist" do
      stub_const("#{described_class}::FLIGHT_DATA_PATH", Rails.root.join("nonexistent.txt"))
      expect {
        described_class.reduce_seats("AI202", "2025-07-15", "Economic", 1)
      }.not_to raise_error
    end

    it "leaves the file unchanged if flight number or date does not match" do
      described_class.reduce_seats("WRONG", "2025-07-15", "Economic", 1)
      expect(File.readlines(test_data_path).map(&:strip)).to eq(original_lines)
    end

    it "skips malformed lines and processes valid ones" do
      expect {
        described_class.reduce_seats("AI202", "2025-07-15", "Economic", 1)
      }.not_to raise_error

      expect(read_fields[9].to_i).to eq(9)
    end

    it "removes the temp file after successful update" do
      described_class.reduce_seats("AI202", "2025-07-15", "Economic", 1)
      expect(File.exist?("#{test_data_path}.tmp")).to be false
    end

    it "cleans up temp file if an error occurs during write" do
      allow(FileUtils).to receive(:mv).and_raise(StandardError.new("simulated move error"))

      expect {
        described_class.reduce_seats("AI202", "2025-07-15", "Economic", 1)
      }.to raise_error(StandardError, "simulated move error")

      expect(File.exist?("#{test_data_path}.tmp")).to be false
    end
  end
end
