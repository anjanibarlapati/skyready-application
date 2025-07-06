require 'rails_helper'

RSpec.describe "Flight search dropdown", type: :system, js: true do
  before do
    driven_by(:selenium_chrome_headless)
    visit root_path
  end

  it "shows dropdown on focusing source input" do
    find('#source-input').click
    expect(page).to have_selector('#source-input-list', visible: true)
  end

  it "shows dropdown on focusing destination input" do
    find('#destination-input').click
    expect(page).to have_selector('#destination-input-list', visible: true)
  end

  it "filters cities based on user input in source" do
    fill_in 'source-input', with: 'Del'

    within '#source-input-list' do
      expect(page).to have_content('Delhi')
      expect(page).not_to have_content('Mumbai')
    end
  end

  it "filters cities based on user input in destination" do
    fill_in 'destination-input', with: 'Goa'

    within '#destination-input-list' do
      expect(page).to have_content('Goa')
      expect(page).not_to have_content('Delhi')
    end
  end

  it "allows selecting different cities for source and destination" do
    find('#source-input').click
    within '#source-input-list' do
      find('.dropdown-item', text: 'Delhi').click
    end

    find('#destination-input').click
    within '#destination-input-list' do
      find('.dropdown-item', text: 'Mumbai').click
    end

    expect(find('#source-input').value).to eq 'Delhi'
    expect(find('#destination-input').value).to eq 'Mumbai'
    expect(page).not_to have_content('Source and destination cannot be the same.')
  end

  it "shows error if same city is selected for source and destination" do
    find('#source-input').click
    within '#source-input-list' do
      find('.dropdown-item', text: 'Delhi').click
    end

    find('#destination-input').click
    within '#destination-input-list' do
      find('.dropdown-item', text: 'Delhi').click
    end

    expect(find('#destination-input').value).to eq ''
    expect(page).to have_content('Source and destination cannot be the same.')
  end

  it "clears error message when valid selection is made after error" do
    find('#source-input').click
    within '#source-input-list' do
      find('.dropdown-item', text: 'Goa').click
    end

    find('#destination-input').click
    within '#destination-input-list' do
      find('.dropdown-item', text: 'Goa').click
    end

    expect(page).to have_content('Source and destination cannot be the same.')

    find('#destination-input').click
    within '#destination-input-list' do
      find('.dropdown-item', text: 'Delhi').click
    end

    expect(page).not_to have_content('Source and destination cannot be the same.')
    expect(find('#destination-input').value).to eq 'Delhi'
  end
end
