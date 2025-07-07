require 'rails_helper'

RSpec.describe "shared/_input_dropdown.html.erb", type: :view do
  it "renders input dropdown with correct id, placeholder, name and options" do
    render partial: "shared/input_dropdown", locals: {
      id: "source-input",
      placeholder: "Enter source city",
      name: "source",
      options: ["Delhi", "Mumbai", "Bengaluru"]
    }

    expect(rendered).to have_selector("input#source-input[placeholder='Enter source city'][name='source']")

    expect(rendered).to have_selector("div#source-input-list.dropdown-list")

    expect(rendered).to have_selector(".dropdown-item", text: "Delhi")
    expect(rendered).to have_selector(".dropdown-item", text: "Mumbai")
    expect(rendered).to have_selector(".dropdown-item", text: "Bengaluru")
  end
end
