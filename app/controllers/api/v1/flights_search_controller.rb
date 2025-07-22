module Api
  module V1
    class FlightsSearchController < Api::BaseController
      def search
        source, destination, class_type, travellers_count, parsed_datetime = extract_search_params

        error = validate_search_input(source, destination, class_type, travellers_count, parsed_datetime)
        return render_error(error[:status], error[:message]) if error

        result = FlightSearchService.search(source, destination, parsed_datetime, travellers_count, class_type)
        return render_error(:not_found, "Flights are not operating between given source and destination") unless result[:found_route]
        return render_error(:conflict, "No flights available on the selected date") unless result[:found_date]
        return render_error(:conflict, "No seats available for #{class_type} class on selected date") unless result[:seats_available]

        render json: { flights: result[:flights] }, status: :ok
      rescue => e
        render_error(:internal_server_error, "Something went wrong while searching flights. Please try again.")
      end

      private

      def extract_search_params
        source      = params[:source]&.strip
        destination = params[:destination]&.strip
        class_type  = (params[:class_type] || "Economy").strip
        travellers_count = params[:travellers_count].to_i
        travellers_count = 1 if travellers_count <= 0

        parsed_datetime =
          begin
            if params[:departure_date].present?
              Time.zone.parse(params[:departure_date])
            else
              Time.zone.now
            end
          rescue ArgumentError, TypeError
            nil
          end

        valid_classes = [ "Economy", "Second Class", "First Class" ]
        class_type = "Economy" unless valid_classes.include?(class_type)

        [ source, destination, class_type, travellers_count, parsed_datetime ]
      end

      def validate_search_input(source, destination, class_type, travellers_count, parsed_datetime)
        return { status: :bad_request, message: "Source and destination are required" } if source.blank? || destination.blank?
        return { status: :bad_request, message: "Source and destination cannot be the same" } if source.downcase == destination.downcase
        return { status: :unprocessable_entity, message: "Travellers count must be between 1 to 9" } unless travellers_count.between?(1, 9)
        return { status: :bad_request, message: "Invalid departure date format" } unless parsed_datetime
        nil
      end
    end
  end
end
