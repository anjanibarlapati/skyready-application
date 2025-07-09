require 'rails_helper'

RSpec.describe FlightsController, type: :request do
  describe "GET /flights/book" do
    context "when flight params are present" do
      let(:flight_params) do
        {
          flight_number: "AI202",
          departure_date: "2025-07-20",
          class_type: "Economic",
          travellers_count: 2
        }
      end

      it "renders the book template with @flight assigned" do
        get book_flight_path, params: { flight: flight_params }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Confirm Your Flight")
      end
    end

    context "when flight params are missing" do
      it "redirects to root with alert" do
        get book_flight_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /flights/confirm" do
    let(:flight_data) do
      {
        flight_number: "AI202",
        departure_date: "2025-07-20",
        class_type: "Economic",
        travellers_count: 2
      }
    end

    before do
      allow(FlightDataUpdater).to receive(:reduce_seats)
    end

    it "calls FlightDataUpdater with correct arguments" do
      post confirm_flight_path, params: { flight: flight_data.to_json }

      expect(FlightDataUpdater).to have_received(:reduce_seats).with(
        "AI202", "2025-07-20", "Economic", 2
      )
    end

    it "sets a flash notice and redirects to root_path" do
      post confirm_flight_path, params: { flight: flight_data.to_json }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:notice]).to eq("🎉 Booking confirmed successfully!")
    end
  end
end
