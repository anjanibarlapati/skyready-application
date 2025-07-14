require 'rails_helper'

RSpec.describe "Api::V1::Cities", type: :request do
  describe "GET /api/v1/cities" do
    let(:test_data_path) { Rails.root.join("spec/fixtures/data/test_cities_data.txt") }

    before do
      FileUtils.mkdir_p(File.dirname(test_data_path))

      File.open(test_data_path, "w") do |file|
        file.puts [
          "AI202,Air India,Delhi,Mumbai,2025-07-19,18:00,2025-07-19,19:30,100,20,50,40,20,16,4000,6000,8000",
          "6E501,IndiGo,Mumbai,Goa,2025-07-11,09:15,2025-07-11,11:00,100,0,50,0,20,0,3000,4500,6000",
          "SG403,SpiceJet,Bengaluru,Delhi,2025-07-12,14:00,2025-07-12,16:45,100,4,50,2,20,2,5000,7500,10000",
          "",
          "INVALID LINE WITHOUT ENOUGH FIELDS"
        ].join("\n")
      end

      allow_any_instance_of(Api::V1::CitiesController)
        .to receive(:file_path)
        .and_return(test_data_path)
    end

    after do
      File.delete(test_data_path) if File.exist?(test_data_path)
    end

    it "returns a list of unique, sorted cities including all valid from and to cities, skipping invalid lines" do
      get "/api/v1/cities"

      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)

      expect(json).to eq([ "Bengaluru", "Delhi", "Goa", "Mumbai" ])
    end

    it "returns an empty array if file is empty" do
      File.write(test_data_path, "")

      get "/api/v1/cities"

      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json).to eq([])
    end

    it "handles a file with only blank lines gracefully" do
      File.write(test_data_path, "\n\n\n")

      get "/api/v1/cities"

      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json).to eq([])
    end

    it "handles a file with invalid lines but still returns valid cities" do
      File.write(test_data_path, [
        "AI202,Air India,Delhi,Mumbai,2025-07-19,18:00,2025-07-19,19:30,100,20,50,40,20,16,4000,6000,8000",
        "INVALID LINE",
        "SG403,SpiceJet,Bengaluru,Delhi,2025-07-12,14:00,2025-07-12,16:45,100,4,50,2,20,2,5000,7500,10000"
      ].join("\n"))

      get "/api/v1/cities"

      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json).to eq([ "Bengaluru", "Delhi", "Mumbai" ])
    end
  end
end
