require 'rails_helper'

RSpec.describe "shared/_flight_detailed_card", type: :view do
  let(:flight) do
    {
      airline_name: "Air Ruby",
      flight_number: "RB123",
      departure_date: "2025-07-16",
      departure_time: "10:30",
      arrival_date: "2025-07-16",
      arrival_time: "14:45",
      source: "Mumbai",
      destination: "Delhi",
      price: 5000
    }
  end

  before do
    render partial: "shared/flight_detailed_card", locals: { flight: flight }
  end

  it "renders the airline name and flight number" do
    expect(rendered).to include("Air Ruby")
    expect(rendered).to include("RB123")
  end

  it "renders the formatted departure and arrival dates" do
    expect(rendered).to include("16, July")
  end

  it "renders the departure time and city" do
    expect(rendered).to include("10:30")
    expect(rendered).to include("Mumbai")
  end

  it "renders the arrival time and city" do
    expect(rendered).to include("14:45")
    expect(rendered).to include("Delhi")
  end

  it "renders the duration using journey_duration helper" do
    expect(rendered).to include("4h 15m")
  end

  it "renders the price with delimiter" do
    expect(rendered).to include("₹ 5,000")
  end

  it "renders the flight line image" do
    expect(rendered).to match(/<img.*?class="detailed-line-img".*?>/)
  end
end
