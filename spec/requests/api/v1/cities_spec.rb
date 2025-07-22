require 'rails_helper'

RSpec.describe "Api::V1::Cities", type: :request do
  describe "GET /api/v1/cities" do
   before do
      Booking.destroy_all
      FlightSeat.destroy_all
      FlightSchedule.destroy_all
      FlightRoute.destroy_all
      Airline.destroy_all
    end

    it "returns an empty array if there are no routes" do
      FlightRoute.delete_all

      get "/api/v1/cities"

      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json).to eq([])
    end

    it "returns a list of unique, sorted cities including all sources and destinations" do
      airline = create(:airline)
      create(:flight_route, airline:, source: "Mumbai", destination: "Delhi")
      create(:flight_route, airline:, source: "Goa", destination: "Bengaluru")

      get "/api/v1/cities"

      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json).to eq([ "Bengaluru", "Delhi", "Goa", "Mumbai" ])
    end
  end
end
