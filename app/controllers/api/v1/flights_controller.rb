module Api
  module V1
    class FlightsController < ApplicationController
      protect_from_forgery with: :null_session

      def search
        source           = params[:source]&.strip
        destination      = params[:destination]&.strip
        departure_date   = params[:departure_date]
        travellers_count = (params[:travellers_count] || 1).to_i
        class_type       = (params[:class_type] || "Economic").strip

        if source.blank? || destination.blank? || departure_date.blank? || travellers_count < 1 || class_type.blank?
          return render json: { error: "All fields are required and travellers count must be at least 1." }, status: :unprocessable_entity
        end

        begin
          parsed_date = Date.parse(departure_date)
        rescue ArgumentError
          return render json: { error: "Invalid departure date format." }, status: :bad_request
        end
        valid_classes = [ "Economic", "Second Class", "First Class" ]
        unless valid_classes.include?(class_type)
          return render json: { error: "Invalid class type. Allowed values: #{valid_classes.join(', ')}" }, status: :bad_request
        end

        flights = FlightDataReader.search(source, destination, parsed_date.to_s, travellers_count, class_type)
        render json: { flights: flights }, status: :ok
      end
    end
  end
end
