require 'rails_helper'

RSpec.describe "shared/_input_dropdown.html.erb", type: :view do
  context "when options are provided" do
    it "renders input dropdown with correct id, placeholder, name, value and options" do
      render partial: "shared/input_dropdown", locals: {
        id: "source-input",
        placeholder: "Enter source",
        name: "source",
        value: "Delhi",
        options: [ "Delhi", "Mumbai", "Bengaluru" ]
      }

      expect(rendered).to have_selector("input#source-input[placeholder='Enter source'][name='source'][value='Delhi']")
      expect(rendered).to have_selector("input[data-dropdown-target='source-input']")

      expect(rendered).to have_selector("div#source-input-list.dropdown-list", visible: false)

      [ "Delhi", "Mumbai", "Bengaluru" ].each do |city|
        expect(rendered).to have_selector(".dropdown-item", text: city, visible: false)
      end

      expect(rendered).to have_selector("span.dropdown-icon img[src*='dropdown-icon']", visible: false)
    end
  end

  context "when options are empty" do
    it "renders input dropdown with no options" do
      render partial: "shared/input_dropdown", locals: {
        id: "destination-input",
        placeholder: "Enter destination",
        name: "destination",
        value: "",
        options: []
      }

      expect(rendered).to have_selector("input#destination-input[placeholder='Enter destination'][name='destination'][value='']")
      expect(rendered).to have_selector("input[data-dropdown-target='destination-input']")

      expect(rendered).to have_selector("div#destination-input-list.dropdown-list", visible: false)

      expect(rendered).not_to have_selector(".dropdown-item")

      expect(rendered).to have_selector("span.dropdown-icon img[src*='dropdown-icon']", visible: false)
    end
  end
end
