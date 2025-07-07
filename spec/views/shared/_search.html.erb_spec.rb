require 'rails_helper'

RSpec.describe "shared/_search.html.erb", type: :view do
  before do
    allow(view).to receive(:params).and_return({
      source: "Delhi",
      destination: "Mumbai",
      departure_date: "2025-07-07"
    })
  end

  it "renders the search form with correct fields, values, and dropdown options" do
    render partial: "shared/search"

    expect(rendered).to have_selector("form[action='/'][method='get']")

    expect(rendered).to have_selector("input#source-input[placeholder='Enter source city'][name='source'][value='Delhi']")
    expect(rendered).to have_selector("div#source-input-list.dropdown-list")
    expect(rendered).to include("Delhi")
    expect(rendered).to include("Mumbai")
    expect(rendered).to include("Bengaluru")

    expect(rendered).to have_selector("input#destination-input[placeholder='Enter destination city'][name='destination'][value='Mumbai']")
    expect(rendered).to have_selector("div#destination-input-list.dropdown-list")
    expect(rendered).to include("Hyderabad")
    expect(rendered).to include("Goa")

    expect(rendered).to have_selector("input#departure_date[name='departure_date'][type='date'][value='2025-07-07']")

    expect(rendered).to have_selector("input[type='submit'][value='Search'].search-button")

    expect(rendered).to have_selector("div#search-error.search-error")
  end

  it "renders today's date in the date picker if no departure_date param is present" do
    allow(view).to receive(:params).and_return({ source: "", destination: "" })

    render partial: "shared/search"

    today = Date.today.strftime("%Y-%m-%d")
    expect(rendered).to have_selector("input#departure_date[value='#{today}']")
  end
end
