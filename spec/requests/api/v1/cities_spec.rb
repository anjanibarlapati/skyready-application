require 'rails_helper'

RSpec.describe "Api::V1::Cities", type: :request do
  describe "GET /api/v1/cities" do
    before do
      Flight.destroy_all
      Airline.destroy_all

      airline = Airline.create!(name: "Test Airline")

      Flight.create!(flight_number: "AI202", airline: airline, source: "Delhi", destination: "Mumbai", departure_datetime: Time.now + 1.day, arrival_datetime: Time.now + 2.days)
      Flight.create!(flight_number: "6E501", airline: airline, source: "Mumbai", destination: "Goa", departure_datetime: Time.now + 3.days, arrival_datetime: Time.now + 4.days)
      Flight.create!(flight_number: "SG403", airline: airline, source: "Bengaluru", destination: "Delhi", departure_datetime: Time.now + 5.days, arrival_datetime: Time.now + 6.days)
    end

    it "returns a list of unique, sorted cities including all sources and destinations" do
      get "/api/v1/cities"

      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)

      expect(json).to eq([ "Bengaluru", "Delhi", "Goa", "Mumbai" ])
    end

    it "returns an empty array if there are no flights" do
      Flight.delete_all

      get "/api/v1/cities"

      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json).to eq([])
    end

    it "returns unique sorted cities even if same city is in multiple flights" do
      airline = Airline.first

      Flight.create!(flight_number: "SG404", airline: airline, source: "Delhi", destination: "Goa", departure_datetime: Time.now + 7.days, arrival_datetime: Time.now + 8.days)

      get "/api/v1/cities"

      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)

      expect(json).to eq([ "Bengaluru", "Delhi", "Goa", "Mumbai" ])
    end
  end
end
