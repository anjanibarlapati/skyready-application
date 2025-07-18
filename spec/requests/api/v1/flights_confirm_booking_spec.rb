require 'rails_helper'

RSpec.describe "Api::V1::FlightsController", type: :request do
  let(:confirm_booking_path) { "/api/v1/flights/confirm-booking" }

  let(:valid_booking_params) do
    {
      flight: {
        flight_number: "AI101",
        departure_date: "2025-07-20",
        class_type: "Economy",
        travellers_count: 2
      }
    }
  end

  describe "POST /api/v1/flights/confirm-booking" do
    context "with valid parameters" do
      it "returns success when booking is confirmed" do
        allow(FlightService).to receive(:reduce_seats).and_return(true)

        post confirm_booking_path, params: valid_booking_params

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["message"]).to eq("Booking confirmed")
      end
    end

    context "when flight data is missing" do
      it "returns 400 with appropriate error message" do
        post confirm_booking_path, params: {}
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["message"]).to eq("Flight data is required")
      end
    end

    context "when flight_number or departure_date is missing" do
      it "returns 422 if flight_number is blank" do
        params = { flight: valid_booking_params[:flight].merge(flight_number: "") }
        post confirm_booking_path, params: params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["message"]).to eq("Flight number and departure date are required")
      end
    end

    context "when travellers_count is out of range" do
      it "returns 422 if travellers_count is zero" do
        params = { flight: valid_booking_params[:flight].merge(travellers_count: 0) }
        post confirm_booking_path, params: params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["message"]).to eq("Travelers count should be between 1 and 9")
      end

      it "returns 422 if travellers_count is more than 9" do
        params = { flight: valid_booking_params[:flight].merge(travellers_count: 10) }
        post confirm_booking_path, params: params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["message"]).to eq("Travelers count should be between 1 and 9")
      end
    end

    context "when booking fails due to unavailable seats or DB issue" do
      it "returns 409 with appropriate error message" do
        allow(FlightService).to receive(:reduce_seats).and_return(false)

        post confirm_booking_path, params: valid_booking_params

        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)["message"]).to eq("Booking failed. Please try again or select a different flight")
      end
    end

    context "when internal server error occurs" do
      it "returns 500 with generic message" do
        allow(FlightService).to receive(:reduce_seats).and_raise(StandardError.new("unexpected error"))

        post confirm_booking_path, params: valid_booking_params

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)["message"]).to eq("Failed to book. Please try again later")
      end
    end
  end
end
