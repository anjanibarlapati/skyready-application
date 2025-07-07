require 'rails_helper'

RSpec.describe "home/index.html.erb", type: :view do
  before do
    stub_template "shared/_search.html.erb" => "<div class='stubbed-search'></div>"
    stub_template "shared/_flight_result_card.html.erb" => "<div class='stubbed-flight-card'></div>"
  end

  context "when page loads without search" do
    before do
      assign(:searched, false)
      assign(:flights, [])
      render
    end

    it "renders About Us section" do
      expect(rendered).to include("About Us")
      expect(rendered).to include("SkyReady is a simple and reliable flight booking platform")
    end

    it "renders #about-us section with ID" do
      expect(rendered).to have_css("section#about-us")
    end

    it "renders slider image with correct ID" do
      expect(rendered).to have_selector("img#slider")
      expect(rendered).to match(/slide1.*\.jpg/)
    end

    it "renders slider tagline text" do
      expect(rendered).to include("Let’s Fly")
      expect(rendered).to include("One Tap To Take Off")
    end

    it "includes the slider JavaScript" do
      expect(rendered).to include("setInterval")
      expect(rendered).to include("slider.src = images[index];")
    end

    it "does not render flight results container" do
      expect(rendered).not_to have_css(".flight-results-container")
    end
  end

  context "when search has results" do
    before do
      assign(:searched, true)
      assign(:flights, [
        { flight_number: "SK101", source: "Delhi", destination: "Mumbai" },
        { flight_number: "SK102", source: "Delhi", destination: "Chennai" }
      ])
      render
    end

    it "renders flight results container" do
      expect(rendered).to have_css(".flight-results-container")
      expect(rendered).to include("Available Flights")
    end

    it "renders one flight card per result" do
      expect(rendered.scan("stubbed-flight-card").count).to eq(2)
    end
  end

  context "when search has no results" do
    before do
      assign(:searched, true)
      assign(:flights, [])
      render
    end

    it "renders flight results container with no results message" do
      expect(rendered).to have_css(".flight-results-container")
      expect(rendered).to include("No flights found for the selected route.")
    end
  end
end
