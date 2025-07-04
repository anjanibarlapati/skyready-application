require 'rails_helper'

RSpec.describe "home/index.html.erb", type: :view do
  it "renders the About Us section" do
    render

    expect(rendered).to include("About Us")
    expect(rendered).to include("SkyReady is a simple and reliable flight booking platform")
  end

  it "has the #about-us section ID" do
    render

    expect(rendered).to have_css("section#about-us")
  end
end
