require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe "GET #index" do
    context "when no params are provided" do
      it "does not perform a search and sets defaults" do
        get :index

        expect(assigns(:searched)).to eq(false)
        expect(assigns(:flights)).to eq([])
      end
    end

    context "when source and destination are provided without departure_date" do
      it "sets searched to true and fetches flights" do
        fake_flights = [
          { flight_number: "AI101", source: "Delhi", destination: "Mumbai" }
        ]

        expect(FlightDataReader).to receive(:search)
          .with("Delhi", "Mumbai", nil)
          .and_return(fake_flights)

        get :index, params: { source: "Delhi", destination: "Mumbai" }

        expect(assigns(:searched)).to eq(true)
        expect(assigns(:flights)).to eq(fake_flights)
      end
    end

    context "when source, destination, and departure_date are provided" do
      it "sets searched to true and fetches flights with date" do
        fake_flights = [
          { flight_number: "AI102", source: "Delhi", destination: "Mumbai", departure_date: "2025-07-07" }
        ]

        expect(FlightDataReader).to receive(:search)
          .with("Delhi", "Mumbai", "2025-07-07")
          .and_return(fake_flights)

        get :index, params: { source: "Delhi", destination: "Mumbai", departure_date: "2025-07-07" }

        expect(assigns(:searched)).to eq(true)
        expect(assigns(:flights)).to eq(fake_flights)
      end
    end

    context "when only source is provided" do
      it "does not perform a search" do
        get :index, params: { source: "Delhi" }

        expect(assigns(:searched)).to eq(false)
        expect(assigns(:flights)).to eq([])
      end
    end

    context "when only destination is provided" do
      it "does not perform a search" do
        get :index, params: { destination: "Mumbai" }

        expect(assigns(:searched)).to eq(false)
        expect(assigns(:flights)).to eq([])
      end
    end
  end
end
