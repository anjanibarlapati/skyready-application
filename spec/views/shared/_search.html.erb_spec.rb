require 'rails_helper'

RSpec.describe "shared/_search.html.erb", type: :view do
  context "when params are present" do
    before do
      allow(view).to receive(:params).and_return({
        source: "Delhi",
        destination: "Mumbai",
        departure_date: "2025-07-07",
        travellers_count: "3"
      })
    end

    it "renders the search form with all fields, values, dropdown options, and travellers input" do
      render partial: "shared/search"

      today = Date.today.strftime("%Y-%m-%d")

      expect(rendered).to have_selector("form[action='/'][method='get']")

      expect(rendered).to have_selector("input#source-input[placeholder='Enter source city'][name='source'][value='Delhi']")
      expect(rendered).to include("Delhi")
      expect(rendered).to include("Mumbai")
      expect(rendered).to include("Bengaluru")

      expect(rendered).to have_selector("input#destination-input[placeholder='Enter destination city'][name='destination'][value='Mumbai']")
      expect(rendered).to include("Hyderabad")
      expect(rendered).to include("Goa")

      expect(rendered).to have_selector("input#departure_date[name='departure_date'][type='date'][value='2025-07-07'][min='#{today}']")

      expect(rendered).to have_selector("input#travellers_count[type='number'][name='travellers_count'][min='1'][max='9'][value='3'][readonly]")

      expect(rendered).to have_selector("button.counter-btn", text: "-")
      expect(rendered).to have_selector("button.counter-btn", text: "+")

      expect(rendered).to have_selector("input[type='submit'][value='Search'].search-button")

      expect(rendered).to have_selector("div#search-error.search-error")
    end
  end

  context "when params are absent" do
    before do
      allow(view).to receive(:params).and_return({})
    end

    it "renders default values for fields" do
      render partial: "shared/search"

      today = Date.today.strftime("%Y-%m-%d")

      expect(rendered).to have_selector("input#source-input[name='source'][value='']")
      expect(rendered).to have_selector("input#destination-input[name='destination'][value='']")

      expect(rendered).to have_selector("input#departure_date[value='#{today}'][min='#{today}']")

      expect(rendered).to have_selector("input#travellers_count[value='1']")
    end
  end
end
