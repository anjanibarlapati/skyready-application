require 'rails_helper'

RSpec.describe "shared/_input_dropdown.html.erb", type: :view do
  context "when options are provided" do
    it "renders input dropdown with correct id, placeholder, name, value and options" do
      render partial: "shared/input_dropdown", locals: {
        id: "source-input",
        placeholder: "Enter source city",
        name: "source",
        value: "Delhi",
        options: [ "Delhi", "Mumbai", "Bengaluru" ]
      }

      expect(rendered).to have_selector("input#source-input[placeholder='Enter source city'][name='source'][value='Delhi']")
      expect(rendered).to have_selector("input[data-dropdown-target='source-input']")

      expect(rendered).to have_selector("div#source-input-list.dropdown-list")

      expect(rendered).to have_selector(".dropdown-item", text: "Delhi")
      expect(rendered).to have_selector(".dropdown-item", text: "Mumbai")
      expect(rendered).to have_selector(".dropdown-item", text: "Bengaluru")
    end
  end

  context "when options are empty" do
    it "renders dropdown list with no options" do
      render partial: "shared/input_dropdown", locals: {
        id: "destination-input",
        placeholder: "Enter destination city",
        name: "destination",
        value: "",
        options: []
      }

      expect(rendered).to have_selector("input#destination-input[placeholder='Enter destination city'][name='destination'][value='']")
      expect(rendered).to have_selector("div#destination-input-list.dropdown-list")
      expect(rendered).not_to have_selector(".dropdown-item")
    end
  end
end
