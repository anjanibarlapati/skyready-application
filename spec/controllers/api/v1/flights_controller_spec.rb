require 'rails_helper'

RSpec.describe "Api::V1::FlightsController", type: :request do
  let(:base_path) { "/api/v1/flights/search" }

  let(:valid_params) do
    {
      source: "Delhi",
      destination: "Mumbai",
      departure_date: "2025-07-20",
      travellers_count: 2,
      class_type: "Economic"
    }
  end

  describe "POST #{'/api/v1/flights/search'}" do
    context "with valid parameters" do
      it "returns success with flights" do
        allow(FlightDataReader).to receive(:search).and_return([ { flight_number: "AI101" } ])

        post base_path, params: valid_params

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body).to have_key("flights")
      end
    end

    context "when required fields are missing or invalid" do
      it "returns error if source is blank" do
        post base_path, params: valid_params.merge(source: "")

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("All fields are required and travellers count must be at least 1.")
      end

      it "returns error if destination is blank" do
        post base_path, params: valid_params.merge(destination: "")

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error if departure_date is blank" do
        post base_path, params: valid_params.merge(departure_date: "")

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error if class_type is blank" do
        post base_path, params: valid_params.merge(class_type: "")

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error if travellers_count is less than 1" do
        post base_path, params: valid_params.merge(travellers_count: 0)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when departure_date format is invalid" do
      it "returns error with bad_request status" do
        post base_path, params: valid_params.merge(departure_date: "invalid-date")

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid departure date format.")
      end
    end

    context "when class_type is not among allowed values" do
      it "returns error with bad_request status" do
        post base_path, params: valid_params.merge(class_type: "Luxury")

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid class type. Allowed values: Economic, Second Class, First Class")
      end
    end
  end
end
