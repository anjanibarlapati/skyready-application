require 'rails_helper'

RSpec.describe "shared/_footer.html.erb", type: :view do
  it "renders the footer with expected content" do
    render
    expect(rendered).to include("© 2025 SkyReady. All rights reserved.")
    expect(rendered).to have_selector("footer")
  end
end
