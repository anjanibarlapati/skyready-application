require 'rails_helper'

RSpec.describe "shared/_flight_result_card.html.erb", type: :view do
  context "when arrival_date_difference is present" do
    it "renders the flight card with date difference badge and all details" do
      flight = {
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
    it "renders the flight card without date difference badge" do
      flight = {
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
end
