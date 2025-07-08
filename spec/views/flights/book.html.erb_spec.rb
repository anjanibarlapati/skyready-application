require 'rails_helper'

RSpec.describe "flights/book.html.erb", type: :view do
  let(:flight) do
    {
      flight_number: "AI202",
      airline_name: "Air India",
      source: "Delhi",
      destination: "Mumbai",
      departure_date: "2025-07-15",
      departure_time: "18:00",
      arrival_date: "2025-07-15",
      arrival_time: "20:00",
      base_price: 4000,
      price: 5000,
      travellers_count: 2,
      class_type: "Economic"
    }
  end

  before do
    assign(:flight, flight)
    render
  end

  it "renders the flight_result_card partial with flight and hide_book_button: true" do
    expect(view).to render_template(partial: "shared/_flight_result_card", locals: { flight: flight, hide_book_button: true })
  end

  it "displays the Fare Summary header" do
    expect(rendered).to have_selector("h2", text: "Fare Summary")
  end

  it "displays correct base fare" do
    base_total = 4000 * 2
    expect(rendered).to include("₹ #{base_total}")
  end

  it "displays correct taxes and fees" do
    taxes = (5000 - 4000) * 2
    expect(rendered).to include("₹ #{taxes}")
  end

  it "displays correct total fare" do
    total = 5000 * 2
    expect(rendered).to include("₹ #{total}")
  end

  it "has a Confirm Booking button" do
    expect(rendered).to have_selector("form button", text: "Confirm Booking")
  end

  it "submits to confirm_flight_path with POST method and JSON-encoded flight" do
    expect(rendered).to have_selector("form[action='#{confirm_flight_path(flight: flight.to_json)}'][method='post']")
  end
end
