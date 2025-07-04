require 'rails_helper'

RSpec.describe "home/index.html.erb", type: :view do
  it "displays the welcome heading and subtext" do
    render

    expect(rendered).to include("Welcome to SkyReady")
    expect(rendered).to include("Your journey starts here.")
    expect(rendered).to include("✈️")
  end
end
