require 'rails_helper'

RSpec.describe Api::V1::CitiesController, type: :controller do
  describe "#file_path" do
    it "returns the correct data file path" do
      controller_instance = Api::V1::CitiesController.new
      expected_path = Rails.root.join("app/assets/data/data.txt")

      expect(controller_instance.file_path).to eq(expected_path)
    end
  end
end
