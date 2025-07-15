module Api
  module V1
    class FlightsController < ApplicationController
      protect_from_forgery with: :null_session

      def search
        source      = params[:source]&.strip
        destination = params[:destination]&.strip
        class_type  = (params[:class_type] || "Economy").strip

        if source.blank? || destination.blank?
          return render json: { message: "Source and destination are required" }, status: :unprocessable_entity
        end
        if source ==  destination
          return render json: { message: "Source and destination cannot be same" }, status: :unprocessable_entity
        end


        travellers_count = params[:travellers_count].to_i

        if travellers_count > 9
          return render json: { message: "Travellers count should be in between 1 to 9" }, status: :unprocessable_entity
        end

        travellers_count = 1 if travellers_count <= 0

        departure_date = params[:departure_date]
        parsed_date =
          begin
            departure_date.present? ? Date.parse(departure_date) : Date.today
          rescue ArgumentError
            return render json: { message: "Invalid departure date format" }, status: :bad_request
          end

        valid_classes = [ "Economy", "Second Class", "First Class" ]
        class_type = "Economy" unless valid_classes.include?(class_type)

         begin
          result = FlightDataReader.search(source, destination, parsed_date, travellers_count, class_type)

          unless result[:found_route]
            return render json: { message: "No flights found for given source and destination" }, status: :not_found
          end

          unless result[:found_date]
            return render json: { message: "No flights available on the selected date" }, status: :conflict
          end

          unless result[:seats_available]
            return render json: { message: "No seats available for #{class_type} class on selected date" }, status: :unprocessable_entity
          end

          render json: { flights: result[:flights] }, status: :ok
        rescue => e
          render json: { message: "Failed to retrieve flight data. Please try again later." }, status: :internal_server_error
        end
      end
    end
  end
end
