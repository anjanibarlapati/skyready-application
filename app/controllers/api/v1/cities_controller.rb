module Api
  module V1
    class CitiesController < Api::BaseController
      def index
        cities = []

        File.foreach(file_path) do |line|
          next if line.strip.empty?
          data = line.strip.split(",")
          next if data.size < 4
          from_city = data[2]
          to_city = data[3]
          cities << from_city
          cities << to_city
        end

        unique_cities = cities.uniq.sort

        render json: unique_cities
      end

      def file_path
        Rails.root.join("app/assets/data/data.txt")
      end
    end
  end
end
