require 'rails_helper'

RSpec.describe "Api::V1::FlightsController - confirm_booking", type: :request do
  let(:endpoint) { "/api/v1/flights/confirm-booking" }

  let(:valid_flight_data) do
    {
      flight_number: "AI202",
      departure_date: "2025-07-20T10:00:00",
      class_type: "Economy",
      travellers_count: 2
    }
  end

  describe "POST #{'/api/v1/flights/confirm-booking'}" do
    context "with valid data" do
      it "returns success message and 200" do
        allow(FlightDataUpdater).to receive(:reduce_seats).and_return(true)

        post endpoint, params: { flight: valid_flight_data }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["message"]).to eq("Booking confirmed")
      end
    end

    context "when flight data is missing" do
      it "returns 400 with message" do
        post endpoint, params: {}

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["message"]).to eq("Flight data is required")
      end
    end

    context "when flight number or date is missing" do
      it "returns 422 when flight number is missing" do
        post endpoint, params: { flight: valid_flight_data.except(:flight_number) }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["message"]).to eq("Flight number and departure date are required")
      end

      it "returns 422 when departure_date is missing" do
        post endpoint, params: { flight: valid_flight_data.except(:departure_date) }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["message"]).to eq("Flight number and departure date are required")
      end
    end

    context "when departure_date is invalid" do
      it "returns 400 with message" do
        post endpoint, params: {
          flight: valid_flight_data.merge(departure_date: "invalid-date")
        }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["message"]).to eq("Invalid departure date format")
      end
    end

    context "when class_type is invalid" do
      it "defaults to Economy and proceeds" do
        allow(FlightDataUpdater).to receive(:reduce_seats).and_return(true)

        post endpoint, params: {
          flight: valid_flight_data.merge(class_type: "Business")
        }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["message"]).to eq("Booking confirmed")
      end
    end

    context "when travellers_count is invalid" do
      it "returns error for 0 or negative count" do
        post endpoint, params: {
          flight: valid_flight_data.merge(travellers_count: 0)
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["message"]).to eq("Travelers count should be between 1 and 9")
      end

      it "returns error for more than 9 travellers" do
        post endpoint, params: {
          flight: valid_flight_data.merge(travellers_count: 12)
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["message"]).to eq("Travelers count should be between 1 and 9")
      end
    end

    context "when booking fails due to unavailable seats or mismatch" do
      it "returns 409 with message" do
        allow(FlightDataUpdater).to receive(:reduce_seats).and_return(false)

        post endpoint, params: { flight: valid_flight_data }

        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)["message"]).to eq("Booking failed. Please try again or select a different flight")
      end
    end

    context "when internal error occurs" do
      it "returns 500 with message" do
        allow(FlightDataUpdater).to receive(:reduce_seats).and_raise(StandardError.new("boom"))

        post endpoint, params: { flight: valid_flight_data }

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)["message"]).to eq("Failed to book. Please try again later")
      end
    end
  end
end
