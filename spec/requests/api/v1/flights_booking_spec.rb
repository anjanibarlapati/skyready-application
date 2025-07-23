require 'rails_helper'

RSpec.describe Api::V1::FlightsBookingController, type: :controller do
  describe "POST /api/v1/flights/confirm-booking" do
    let(:flight) { Flight.create!(flight_number: "AI101", flight_route: FlightRoute.create!(airline: Airline.create!(name: "TestAir"), source: "Delhi", destination: "Goa")) }
    let(:schedule) do
      FlightSchedule.create!(
        flight: flight,
        departure_time: "10:00:00",
        arrival_time: "12:00:00",
        start_date: Date.today,
        recurring: false
      )
    end
    let!(:seat) do
      FlightSeat.create!(
        flight_schedule: schedule,
        class_type: "Economy",
        total_seats: 100,
        base_price: 5000
      )
    end
    let!(:booking) do
      Booking.create!(
        flight_schedule: schedule,
        flight_date: Date.today,
        class_type: "Economy",
        available_seats: 10
      )
    end

    before { schedule; seat; booking }

    context "integration test for successful booking" do
      it "returns success when booking is confirmed" do
        post :confirm_booking, params: {
          flight: {
            flight_number: flight.flight_number,
            departure_date: "#{Date.today} 10:00:00",
            class_type: "Economy",
            travellers_count: 2
          }
        }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["message"]).to eq("Booking confirmed")
      end
    end

    context "controller tests with service mocked" do
      before { allow(FlightBookingService).to receive(:book_seats).and_return(true) }

      it "returns error if flight params are missing" do
        post :confirm_booking, params: { flight: nil }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["message"]).to eq("Flight data is required")
      end

      it "returns error if departure_date is invalid" do
        allow(Time.zone).to receive(:parse).and_raise(ArgumentError)

        post :confirm_booking, params: {
          flight: {
            flight_number: flight.flight_number,
            departure_date: "invalid-date",
            class_type: "Economy",
            travellers_count: 1
          }
        }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["message"]).to eq("Invalid departure date format")
      end

      it "returns success when travellers_count is 0 (gets corrected to 1)" do
        post :confirm_booking, params: {
          flight: {
            flight_number: flight.flight_number,
            departure_date: "#{Date.today} 10:00:00",
            class_type: "Economy",
            travellers_count: 0
          }
        }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["message"]).to eq("Booking confirmed")
      end

      it "returns internal server error when FlightBookingService raises an exception" do
        allow(FlightBookingService).to receive(:book_seats).and_raise(StandardError.new("Database error"))

        post :confirm_booking, params: {
          flight: {
            flight_number: flight.flight_number,
            departure_date: "#{Date.today} 10:00:00",
            class_type: "Economy",
            travellers_count: 1
          }
        }
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)["message"]).to eq("Failed to book. Please try again later")
      end
    end
  end
end
