require 'rails_helper'

RSpec.describe "Image slider", type: :system do
  it "cycles through images every 2 seconds" do
    driven_by(:selenium, using: :headless_firefox)

    visit root_path

    slider = find('#slider')
    first_src = slider[:src]

    sleep 2.1
    second_src = slider[:src]

    expect(second_src).not_to eq(first_src)

    sleep 2.1
    third_src = slider[:src]

    expect(third_src).not_to eq(second_src)
  end
end
