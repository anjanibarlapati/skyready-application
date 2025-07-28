require "rails_helper"

RSpec.describe "POST /api/v1/flights/confirm-booking", type: :request do
  let(:flight) { create(:flight) }
  let(:flight_schedule) { create(:flight_schedule, flight: flight) }

  let(:valid_params) do
    {
      flight: {
        flight_number: flight.flight_number,
        departure_date: Date.today.to_s,
        class_type: "Economy",
        travellers_count: 2
      }
    }
  end

  context "when booking is successful" do
    before do
      allow(FlightBookingService).to receive(:book_seats).and_return(true)
      post "/api/v1/flights/confirm-booking", params: valid_params
    end

    it "returns status 200 with confirmation message" do
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Booking confirmed")
    end
  end

  context "when booking fails" do
    before do
      allow(FlightBookingService).to receive(:book_seats).and_return(false)
      post "/api/v1/flights/confirm-booking", params: valid_params
    end

    it "returns conflict with failure message" do
      expect(response).to have_http_status(:conflict)
      expect(JSON.parse(response.body)["message"]).to eq("Booking failed. Please try again or select a different flight")
    end
  end

  context "when required params are missing" do
    it "returns bad request when no flight data" do
      post "/api/v1/flights/confirm-booking", params: {}
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["message"]).to eq("Flight data is required")
    end
  end

  context "when departure date is invalid" do
    it "falls back to booking and returns conflict if booking fails" do
      allow(FlightBookingService).to receive(:book_seats).and_return(false)

      post "/api/v1/flights/confirm-booking", params: {
        flight: valid_params[:flight].merge(departure_date: "not-a-date")
      }

      expect(response).to have_http_status(:conflict)
      expect(JSON.parse(response.body)["message"]).to eq("Booking failed. Please try again or select a different flight")
    end
  end

  context "when travellers count is out of range (0)" do
    it "falls back to 1 and returns conflict if booking fails" do
      allow(FlightBookingService).to receive(:book_seats).and_return(false)

      post "/api/v1/flights/confirm-booking", params: {
        flight: valid_params[:flight].merge(travellers_count: 0)
      }

      expect(response).to have_http_status(:conflict)
      expect(JSON.parse(response.body)["message"]).to eq("Booking failed. Please try again or select a different flight")
    end
  end

  context "when an unexpected error occurs" do
    before do
      allow(FlightBookingService).to receive(:book_seats).and_raise(StandardError, "Some error")
      post "/api/v1/flights/confirm-booking", params: valid_params
    end

    it "returns 500 internal server error" do
      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)["message"]).to eq("Failed to book. Please try again later")
    end
  end
end
