require 'rails_helper'

RSpec.describe "shared/_flight_result_card.html.erb", type: :view do
  context "when arrival_date_difference is present" do
    let(:flight) do
      {
        flight_number: "SK123",
        airline_name: "Air India",
        source: "Delhi",
        destination: "Mumbai",
        departure_time: "08:00",
        arrival_time: "10:00",
        arrival_date_difference: "+1",
        seats: 5,
        price: 7800
      }
    end

    it "renders the flight card with all details and date diff" do
      render partial: "shared/flight_result_card", locals: { flight: flight }

      expect(rendered).to have_css(".flight-cards-container")
      expect(rendered).to have_css(".flight-card")
      expect(rendered).to have_css(".flight-details")
      expect(rendered).to have_css(".flight-block-container")
      expect(rendered).to have_css(".flight-icon", text: "✈️")
      expect(rendered).to have_css(".flight-block")
      expect(rendered).to have_css(".departure-block")
      expect(rendered).to have_css(".arrival-block")
      expect(rendered).to have_css(".route-arrow", text: "➡️")
      expect(rendered).to have_css(".seats-block")
      expect(rendered).to have_css(".flight-price")
      expect(rendered).to have_css(".date-diff", text: "+1")

      expect(rendered).to include("Air India")
      expect(rendered).to include("SK123")
      expect(rendered).to include("Delhi")
      expect(rendered).to include("Mumbai")
      expect(rendered).to include("🛫 08:00")
      expect(rendered).to include("🛬 10:00")
      expect(rendered).to include("Seats Available")
      expect(rendered).to include("5")
      expect(rendered).to include("₹ 7,800")
    end
  end

  context "when arrival_date_difference is nil" do
    let(:flight) do
      {
        flight_number: "SK124",
        airline_name: "IndiGo",
        source: "Hyderabad",
        destination: "Chennai",
        departure_time: "09:00",
        arrival_time: "10:30",
        arrival_date_difference: nil,
        seats: 3,
        price: 5600
      }
    end

    it "renders the flight card without date diff" do
      render partial: "shared/flight_result_card", locals: { flight: flight }

      expect(rendered).to include("IndiGo")
      expect(rendered).to include("SK124")
      expect(rendered).to include("Hyderabad")
      expect(rendered).to include("Chennai")
      expect(rendered).to include("🛫 09:00")
      expect(rendered).to include("🛬 10:30")
      expect(rendered).to include("Seats Available")
      expect(rendered).to include("3")
      expect(rendered).to include("₹ 5,600")
      expect(rendered).not_to have_css(".date-diff")
    end
  end

  context "when hide_book_button is not passed" do
    it "renders the Book link" do
      flight = {
        flight_number: "SK125",
        airline_name: "SpiceJet",
        source: "Bangalore",
        destination: "Kolkata",
        departure_time: "07:00",
        arrival_time: "09:00",
        seats: 2,
        price: 6300
      }

      render partial: "shared/flight_result_card", locals: { flight: flight }

      expect(rendered).to have_link("Book", href: book_flight_path(flight: flight))
    end
  end

  context "when hide_book_button is true" do
    it "does not render the Book link" do
      flight = {
        flight_number: "SK126",
        airline_name: "Vistara",
        source: "Pune",
        destination: "Delhi",
        departure_time: "06:00",
        arrival_time: "08:00",
        seats: 4,
        price: 7200
      }

      render partial: "shared/flight_result_card", locals: { flight: flight, hide_book_button: true }

      expect(rendered).not_to have_link("Book")
    end
  end
end
