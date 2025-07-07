require 'rails_helper'

RSpec.describe "shared/_flight_result_card.html.erb", type: :view do
  it "renders the flight card with flight number, source and destination" do
    assign(:flight, { flight_number: "SK123", source: "Delhi", destination: "Mumbai" })

    render partial: "shared/flight_result_card", locals: { flight: { flight_number: "SK123", source: "Delhi", destination: "Mumbai" } }

    expect(rendered).to have_css(".flight-card")
    expect(rendered).to have_css(".flight-info-inline")

    expect(rendered).to include("✈️ SK123")
    expect(rendered).to include("Delhi")
    expect(rendered).to include("to")
    expect(rendered).to include("Mumbai")
  end
end
