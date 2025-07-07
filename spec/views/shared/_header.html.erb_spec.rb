require 'rails_helper'

RSpec.describe "shared/_header.html.erb", type: :view do
  before do
    render
  end

  it "renders the logo image with correct src, alt and class" do
    expect(rendered).to have_css('img.logo-img[alt="SkyReady Logo"]')
  end
  it "renders the Home link with correct text, href and class" do
    expect(rendered).to have_link("Home", href: root_path, class: "nav-button")
  end
  it "renders the About Us link with correct text, href and class" do
    expect(rendered).to have_link("About Us", href: "#about-us", class: "nav-button")
  end
end
