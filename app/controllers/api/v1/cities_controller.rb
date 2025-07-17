module Api
  module V1
    class CitiesController < Api::BaseController
      def index
        from_cities = Flight.distinct.pluck(:source)
        to_cities = Flight.distinct.pluck(:destination)

        unique_cities = (from_cities + to_cities).uniq.sort

        render json: unique_cities
      end
    end
  end
end
