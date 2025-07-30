require "rails_helper"

RSpec.describe "POST /api/v1/flights/confirm-round-trip", type: :request do
  let(:departure_flight) { create(:flight) }
  let(:return_flight) { create(:flight) }

  let(:departure_schedule) { create(:flight_schedule, flight: departure_flight) }
  let(:return_schedule) { create(:flight_schedule, flight: return_flight) }

  let(:valid_params) do
    {
      data: {
        departure_flight_number: departure_flight.flight_number,
        return_flight_number: return_flight.flight_number,
        departure_date: Date.today.to_s,
        return_date: (Date.today + 2.days).to_s,
        class_type: "Economy",
        travellers_count: 2
      }
    }
  end

  context "when booking is successful" do
    before do
      allow(FlightBookingService).to receive(:book_round_trip_seats).and_return(true)
      post "/api/v1/flights/confirm-round-trip", params: valid_params
    end

    it "returns 200 OK with confirmation message" do
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Round-trip booking confirmed")
    end
  end

  context "when booking fails" do
    before do
      allow(FlightBookingService).to receive(:book_round_trip_seats).and_return(false)
      post "/api/v1/flights/confirm-round-trip", params: valid_params
    end

    it "returns 409 Conflict with failure message" do
      expect(response).to have_http_status(:conflict)
      expect(JSON.parse(response.body)["message"]).to eq("Booking failed. Try again or choose different flights.")
    end
  end

  context "when required params are missing" do
    it "returns 400 Bad Request when no data provided" do
      post "/api/v1/flights/confirm-round-trip", params: {}
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["message"]).to eq("Flight data is required")
    end

    it "returns 422 Unprocessable Entity when any field is missing" do
      post "/api/v1/flights/confirm-round-trip", params: {
        data: valid_params[:data].except(:return_date)
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["message"]).to eq("All fields are required")
    end
  end

  context "when date format is invalid" do
    it "returns 400 Bad Request for bad departure or return date" do
      post "/api/v1/flights/confirm-round-trip", params: {
        data: valid_params[:data].merge(departure_date: "invalid", return_date: "still-wrong")
      }
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["message"]).to eq("Invalid date format for departure or return date")
    end
  end

  context "when travellers count is out of range" do
    it "returns 422 Unprocessable Entity when more than 9 travellers" do
      post "/api/v1/flights/confirm-round-trip", params: {
        data: valid_params[:data].merge(travellers_count: 15)
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["message"]).to eq("Travelers count should be between 1 and 9")
    end
  end

  context "when an unexpected error occurs" do
    before do
      allow(FlightBookingService).to receive(:book_round_trip_seats).and_raise(StandardError, "Oops")
      post "/api/v1/flights/confirm-round-trip", params: valid_params
    end

    it "returns 500 Internal Server Error" do
      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)["message"]).to eq("Failed to book round-trip. Please try again later")
    end
  end
end
