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

  it "renders the slider image with correct id and initial src" do
    render

    expect(rendered).to include('id="slider"')
    expect(rendered).to match(/slide1.*\.jpg/)
  end

  it "includes the JavaScript slider logic" do
    render

    expect(rendered).to include('setInterval')
    expect(rendered).to include('slider.src = images[index];')
  end

  it "renders app tagline" do
    render

    expect(rendered).to include("Let’s Fly")
    expect(rendered).to include("One Tap To Take Off")
  end
end
