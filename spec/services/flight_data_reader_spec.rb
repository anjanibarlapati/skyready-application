require 'rails_helper'
require 'active_support/testing/time_helpers'

RSpec.describe FlightDataReader do
  include ActiveSupport::Testing::TimeHelpers

  describe ".search with parameters: source, destination, date, class_type, travellers_count" do
    let(:test_data_path) { Rails.root.join("spec/fixtures/data/flight_data.txt") }

    around(:each) do |example|
      travel_to Time.new(2025, 7, 8, 10, 0, 0) do
        example.run
      end
    end

    before do
      FileUtils.mkdir_p(File.dirname(test_data_path))
      File.open(test_data_path, "w") do |f|
        f.puts [
          "AI202,Air India,Delhi,Mumbai,#{Date.today},18:00,#{Date.today},19:30,100,20,50,40,20,20,140,4000,6000,8000",
          "AI203,Air India,Delhi,Mumbai,#{Date.today + 3},18:00,#{Date.today + 3},20:30,100,20,50,10,20,9,39,4000,6000,8000",
          "AI204,Air India,Delhi,Mumbai,#{Date.today + 3},23:00,#{Date.today + 4},08:30,100,14,50,8,20,6,28,4000,6000,8000",
          "6E501,IndiGo,Mumbai,Goa,#{Date.today + 3},09:15,#{Date.today + 3},11:00,100,0,50,0,20,0,0,3000,4500,6000",
          "SG403,SpiceJet,Bengaluru,Delhi,#{Date.today + 4},14:00,#{Date.today + 4},16:45,100,4,50,2,20,2,8,5000,7500,10000"
        ].join("\n")
      end

      stub_const("#{described_class}::FLIGHT_DATA_PATH", test_data_path)
    end

    after do
      File.delete(test_data_path) if File.exist?(test_data_path)
    end

    def append_test_flight(line)
      File.open(test_data_path, "a") { |f| f.puts line }
    end

    context "basic functionality" do
      it "returns matching flights for valid inputs" do
        result = described_class.search("Delhi", "Mumbai", Date.today.to_s)
        expect(result.map { |f| f[:flight_number] }).to include("AI202")
      end

      it "returns empty if no matching flights" do
        result = described_class.search("Delhi", "Chennai")
        expect(result).to be_empty
      end

      it "is case-insensitive for source and destination" do
        result = described_class.search("delhi", "mumbai", Date.today.to_s)
        expect(result.map { |f| f[:flight_number] }).to include("AI202")
      end

      it "returns all flights matching source and destination when no departure date is provided" do
        result = described_class.search("Delhi", "Mumbai")
        expect(result).not_to be_empty
        expect(result.all? { |f| f[:source] == "Delhi" && f[:destination] == "Mumbai" }).to be true
      end

      it "skips flights with invalid departure time format" do
        append_test_flight "AI999,Air India,Delhi,Mumbai,#{Date.today + 2},99:99,#{Date.today + 2},13:00,100,85,50,40,20,20,140,4000,6000,8000"
        result = described_class.search("Delhi", "Mumbai", (Date.today + 2).to_s, 1, "Economic")
        expect(result.map { |f| f[:flight_number] }).not_to include("AI999")
      end

      it "skips malformed data lines with incorrect number of fields" do
        File.open(test_data_path, "a") { |f| f.puts "BROKEN,LINE,WITH,TOO,FEW,FIELDS" }
        result = described_class.search("Delhi", "Mumbai")
        expect(result.none? { |f| f[:flight_number] == "BROKEN" }).to be true
      end

      it "includes today's flights if time is still ahead" do
        today = Date.today
        future_time = (Time.now + 2.hours).strftime("%H:%M")
        append_test_flight "AI400,Air India,Delhi,Mumbai,#{today},#{future_time},#{today},14:00,100,80,50,40,20,20,140,4000,6000,8000"
        result = described_class.search("Delhi", "Mumbai", today.to_s, 1, "Economic")
        expect(result.map { |f| f[:flight_number] }).to include("AI400")
      end
    end

    context "traveller count validations" do
      it "defaults to 1 if not provided or invalid" do
        [ "", nil, "abc", -3 ].each do |tc|
          result = described_class.search("Delhi", "Mumbai", Date.today.to_s, tc, "Economic")
          expect(result).not_to be_empty
        end
      end

      it "filters flights if travellers_count exceeds available seats" do
        result = described_class.search("Delhi", "Mumbai", Date.today.to_s, 50, "Economic")
        expect(result).to be_empty
      end
    end

    context "class type validations" do
      it "defaults to Economic if blank or nil" do
        [ nil, "" ].each do |ctype|
          result = described_class.search("Delhi", "Mumbai", Date.today.to_s, 1, ctype)
          expect(result.map { |f| f[:flight_number] }).to include("AI202")
        end
      end

      it "returns empty if class_type is invalid" do
        result = described_class.search("Delhi", "Mumbai", Date.today.to_s, 1, "Luxury Class")
        expect(result).to be_empty
      end

      it "skips flights if total seats in selected class are zero or negative" do
        append_test_flight "AI999,Air India,Delhi,Mumbai,#{Date.today + 7},10:00,#{Date.today + 7},12:00,0,10,50,50,20,20,140,4000,6000,8000"
        result = described_class.search("Delhi", "Mumbai", (Date.today + 7).to_s, 1, "Economic")
        expect(result.map { |f| f[:flight_number] }).not_to include("AI999")
      end
    end

context "pricing strategy" do
  it "calculates correct base price for <=30% booked" do
    dep_date = (Date.today + 2).to_s
    append_test_flight "AI301,Air India,Delhi,Mumbai,#{dep_date},12:00,#{dep_date},14:00,100,80,50,40,20,20,140,4000,6000,8000"
    result = described_class.search("Delhi", "Mumbai", dep_date, 1, "Economic")
    flight = result.find { |f| f[:flight_number] == "AI301" }

    booking_multiplier = 1.0
    date_multiplier = 1 + 0.10 * (3 - 2)
    expected_price = (4000 * booking_multiplier * date_multiplier).to_i

    expect(flight[:price]).to eq(expected_price)
  end

  it "adds 20% for 30-50% booked" do
    dep_date = (Date.today + 2).to_s
    append_test_flight "AI302,Air India,Delhi,Mumbai,#{dep_date},15:00,#{dep_date},17:00,100,60,50,40,20,20,140,4000,6000,8000"
    result = described_class.search("Delhi", "Mumbai", dep_date, 1, "Economic")
    flight = result.find { |f| f[:flight_number] == "AI302" }

    booking_multiplier = 1.2
    date_multiplier = 1 + 0.10 * (3 - 2)
    expected_price = (4000 * booking_multiplier * date_multiplier).to_i

    expect(flight[:price]).to eq(expected_price)
  end

  it "adds 10% if flight is 2 days away" do
    dep_date = (Date.today + 2).to_s
    append_test_flight "AI303,Air India,Delhi,Mumbai,#{dep_date},10:00,#{dep_date},12:00,100,80,50,40,20,20,140,4000,6000,8000"
    result = described_class.search("Delhi", "Mumbai", dep_date, 1, "Economic")
    flight = result.find { |f| f[:flight_number] == "AI303" }

    booking_multiplier = 1.0
    date_multiplier = 1 + 0.10 * (3 - 2)
    expected_price = (4000 * booking_multiplier * date_multiplier).to_i

    expect(flight[:price]).to eq(expected_price)
  end

  it "adds ~6% if flight is 7 days away" do
    dep_date = (Date.today + 7).to_s
    append_test_flight "AI304,Air India,Delhi,Mumbai,#{dep_date},23:59,#{dep_date},13:00,100,85,50,40,20,20,140,4000,6000,8000"
    result = described_class.search("Delhi", "Mumbai", dep_date, 1, "Economic")
    flight = result.find { |f| f[:flight_number] == "AI304" }

    booking_multiplier = 1.0
    date_multiplier = (1 + 0.02 * (10 - 7)).clamp(1.0, 1.14)
    expected_price = (4000 * booking_multiplier * date_multiplier).to_i

    expect(flight[:price]).to eq(expected_price)
  end

  it "does not increase price if flight is more than 10 days away" do
    dep_date = (Date.today + 15).to_s
    append_test_flight "AI305,Air India,Delhi,Mumbai,#{dep_date},09:00,#{dep_date},11:00,100,80,50,40,20,20,140,4000,6000,8000"
    result = described_class.search("Delhi", "Mumbai", dep_date, 1, "Economic")
    flight = result.find { |f| f[:flight_number] == "AI305" }

    expect(flight[:price]).to eq(4000)
  end

  it "applies both booking and date multipliers correctly" do
    dep_date = (Date.today + 2).to_s
    append_test_flight "AI306,Air India,Delhi,Mumbai,#{dep_date},10:00,#{dep_date},12:00,100,60,50,40,20,20,140,4000,6000,8000"
    result = described_class.search("Delhi", "Mumbai", dep_date, 1, "Economic")
    flight = result.find { |f| f[:flight_number] == "AI306" }

    booking_multiplier = 1.2
    date_multiplier = 1 + 0.10 * (3 - 2)
    expected_price = (4000 * booking_multiplier * date_multiplier).to_i

    expect(flight[:price]).to eq(expected_price)
  end
end


    context "edge case: same-day past time flights" do
      it "excludes today's flights if departure time has already passed" do
        past_time = (Time.now - 1.hour).strftime("%H:%M")
        append_test_flight "AI307,Air India,Delhi,Mumbai,#{Date.today},#{past_time},#{Date.today},14:00,100,80,50,40,20,20,140,4000,6000,8000"
        result = described_class.search("Delhi", "Mumbai", Date.today.to_s, 1, "Economic")
        expect(result.map { |f| f[:flight_number] }).not_to include("AI307")
      end

      it "handles invalid date format for departure_date gracefully" do
        result = described_class.search("Delhi", "Mumbai", "not-a-date", 1, "Economic")
        expect(result).not_to be_empty
        expect(result.all? { |f| f[:source] == "Delhi" && f[:destination] == "Mumbai" }).to be true
      end
    end
  end
end
