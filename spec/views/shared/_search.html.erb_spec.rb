require 'rails_helper'

RSpec.describe "shared/_search.html.erb", type: :view do
  it "renders the search form with source and destination dropdowns and search button" do
    render partial: "shared/search"

    expect(rendered).to have_selector("form[action='/'][method='get']")

    expect(rendered).to have_selector("input#source-input[placeholder='Enter source city'][name='source']")
    expect(rendered).to have_selector("input#destination-input[placeholder='Enter destination city'][name='destination']")

    expect(rendered).to include("Delhi")
    expect(rendered).to include("Mumbai")

    expect(rendered).to have_selector("input[type='submit'][value='Search'].search-button")

    expect(rendered).to have_selector("div#search-error.search-error")
  end
end
