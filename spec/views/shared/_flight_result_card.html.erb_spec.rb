require 'rails_helper'

RSpec.describe "shared/_flight_result_card.html.erb", type: :view do
  it "renders the flight card with all flight details" do
    flight = {
      flight_number: "SK123",
      airline_name: "Air India",
      source: "Delhi",
      destination: "Mumbai",
      departure_time: "08:00",
      arrival_time: "10:00"
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

    expect(rendered).to include("Air India")
    expect(rendered).to include("SK123")
    expect(rendered).to include("Delhi")
    expect(rendered).to include("Mumbai")
    expect(rendered).to include("🛫 08:00")
    expect(rendered).to include("🛬 10:00")
  end
end
