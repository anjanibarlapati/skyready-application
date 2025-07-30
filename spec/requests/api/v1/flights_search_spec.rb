require 'rails_helper'

RSpec.describe "Api::V1::FlightsSearchController", type: :request do
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

  let(:parsed_response) { JSON.parse(response.body) }

  describe "POST /api/v1/flights/search" do
    context "with valid parameters" do
      it "returns success with flights" do
        allow(FlightSearchService).to receive(:search).and_return({
          flights: [ { flight_number: "AI101" } ],
          found_route: true,
          found_class_type: true,
          found_date: true,
          seats_available: true
        })

        post base_path, params: valid_params

        expect(response).to have_http_status(:ok)
        expect(parsed_response).to have_key("flights")
      end
    end

    context "when required fields are missing" do
      it "returns 400 if source is blank" do
        post base_path, params: valid_params.merge(source: "")
        expect(response).to have_http_status(:bad_request)
        expect(parsed_response["message"]).to eq("Source and destination are required")
      end

      it "returns 400 if destination is blank" do
        post base_path, params: valid_params.merge(destination: "")
        expect(response).to have_http_status(:bad_request)
        expect(parsed_response["message"]).to eq("Source and destination are required")
      end
    end

    context "when source and destination are the same" do
      it "returns 400 with appropriate message" do
        post base_path, params: valid_params.merge(destination: "Delhi")
        expect(response).to have_http_status(:bad_request)
        expect(parsed_response["message"]).to eq("Source and destination cannot be the same")
      end
    end

    context "when departure_date format is invalid" do
      it "returns 400 with error message" do
        post base_path, params: valid_params.merge(departure_date: [])
        expect(response).to have_http_status(:bad_request)
        expect(parsed_response["message"]).to eq("Invalid departure date format")
      end
    end

    context "when travellers count is more than 9" do
      it "returns 422 with error message" do
        post base_path, params: valid_params.merge(travellers_count: 10)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parsed_response["message"]).to eq("Travellers count must be between 1 to 9")
      end
    end

    context "when route is not found" do
      it "returns 404 with appropriate message" do
        allow(FlightSearchService).to receive(:search).and_return({
          flights: [],
          found_route: false,
          found_class_type: false,
          found_date: false,
          seats_available: false
        })

        post base_path, params: valid_params
        expect(response).to have_http_status(:not_found)
        expect(parsed_response["message"]).to eq("Flights are not operating between given source and destination")
      end
    end

    context "when class type is not available for the route" do
      it "returns 409 with appropriate message" do
        allow(FlightSearchService).to receive(:search).and_return({
          flights: [],
          found_route: true,
          found_class_type: false,
          found_date: false,
          seats_available: false
        })

        post base_path, params: valid_params.merge(class_type: "First Class")
        expect(response).to have_http_status(:conflict)
        expect(parsed_response["message"]).to eq("No flights available on the selected date")
      end
    end

    context "when date is not available" do
      it "returns 409 with appropriate message" do
        allow(FlightSearchService).to receive(:search).and_return({
          flights: [],
          found_route: true,
          found_class_type: true,
          found_date: false,
          seats_available: false
        })

        post base_path, params: valid_params
        expect(response).to have_http_status(:conflict)
        expect(parsed_response["message"]).to eq("No flights available on the selected date")
      end
    end

    context "when seats are unavailable" do
      it "returns 409 with appropriate message" do
        allow(FlightSearchService).to receive(:search).and_return({
          flights: [],
          found_route: true,
          found_class_type: true,
          found_date: true,
          seats_available: false
        })

        post base_path, params: valid_params
        expect(response).to have_http_status(:conflict)
        expect(parsed_response["message"]).to eq("No seats available for economy class on selected date")
      end
    end

    context "when internal error occurs" do
      it "returns 500 with generic error message" do
        allow(FlightSearchService).to receive(:search).and_raise(StandardError.new("unexpected"))

        post base_path, params: valid_params
        expect(response).to have_http_status(:internal_server_error)
        expect(parsed_response["message"]).to eq("Something went wrong while searching flights. Please try again.")
      end
    end
  end
end
