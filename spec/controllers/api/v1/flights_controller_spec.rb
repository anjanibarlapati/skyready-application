require 'rails_helper'

RSpec.describe "Api::V1::FlightsController", type: :request do
  let(:base_path) { "/api/v1/flights/search" }

  let(:valid_params) do
    {
      source: "Delhi",
      destination: "Mumbai",
      departure_date: "2025-07-20",
      travellers_count: 2,
      class_type: "Economy"
    }
  end

  describe "POST #{'/api/v1/flights/search'}" do
    context "with valid parameters" do
      it "returns success with flights" do
        allow(FlightDataReader).to receive(:search).and_return({
          flights: [{ flight_number: "AI101" }],
          found_route: true,
          found_date: true,
          seats_available: true
        })

        post base_path, params: valid_params
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body).to have_key("flights")
      end
    end

    context "when required fields are missing" do
      it "returns error if source is blank" do
        post base_path, params: valid_params.merge(source: "")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["message"]).to eq("Source and destination are required")
      end

      it "returns error if destination is blank" do
        post base_path, params: valid_params.merge(destination: "")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["message"]).to eq("Source and destination are required")
      end
    end

    context "when departure_date format is invalid" do
      it "returns error with bad_request status" do
        post base_path, params: valid_params.merge(departure_date: "invalid-date")
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["message"]).to eq("Invalid departure date format")
      end
    end

    context "when route is not found" do
      it "returns 404 with message" do
        allow(FlightDataReader).to receive(:search).and_return({
          flights: [],
          found_route: false,
          found_date: false,
          seats_available: false
        })

        post base_path, params: valid_params
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["message"]).to eq("No flights found for given source and destination")
      end
    end

    context "when date is not available" do
      it "returns 409 with message" do
        allow(FlightDataReader).to receive(:search).and_return({
          flights: [],
          found_route: true,
          found_date: false,
          seats_available: false
        })

        post base_path, params: valid_params
        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)["message"]).to eq("No flights available on the selected date")
      end
    end

    context "when seats are unavailable" do
      it "returns 422 with message" do
        allow(FlightDataReader).to receive(:search).and_return({
          flights: [],
          found_route: true,
          found_date: true,
          seats_available: false
        })

        post base_path, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["message"]).to eq("No seats available for Economy class on selected date")
      end
    end

    context "when internal error occurs" do
      it "returns 500 with generic error message" do
        allow(FlightDataReader).to receive(:search).and_raise(StandardError.new("unexpected"))

        post base_path, params: valid_params
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)["message"]).to eq("Failed to retrieve flight data. Please try again later.")
      end
    end
  end
end
