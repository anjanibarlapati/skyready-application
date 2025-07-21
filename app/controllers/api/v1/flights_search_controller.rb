module Api
  module V1
    class FlightsSearchController < Api::BaseController
      def search
        source, destination, class_type, travellers_count, parsed_date = extract_search_params

        error = validate_search_input(source, destination, class_type, travellers_count, parsed_date)
        return render_error(error[:status], error[:message]) if error

        result = FlightSearchService.search(source, destination, parsed_date, travellers_count, class_type)

        return render_error(:not_found, "Flights are not operating between given source and destination") unless result[:found_route]
        return render_error(:conflict, "No flights available on the selected date") unless result[:found_date]
        return render_error(:conflict, "No seats available for #{class_type} class on selected date") unless result[:seats_available]

        render json: { flights: result[:flights] }, status: :ok
      rescue => e
        render_error(:internal_server_error, "Failed to retrieve flight data. Please try again later.")
      end

      private

      def extract_search_params
        source      = params[:source]&.strip
        destination = params[:destination]&.strip
        class_type  = (params[:class_type] || "Economy").strip
        travellers_count = params[:travellers_count].to_i
        travellers_count = 1 if travellers_count <= 0

        parsed_date =
          begin
            if params[:departure_date].present?
              Time.zone.parse(params[:departure_date]).strftime("%Y-%m-%d %H:%M:%S")
            else
              Time.current.strftime("%Y-%m-%d %H:%M:%S")
            end
          rescue ArgumentError, TypeError
            nil
          end

        valid_classes = [ "Economy", "Second Class", "First Class" ]
        class_type = "Economy" unless valid_classes.include?(class_type)

        [ source, destination, class_type, travellers_count, parsed_date ]
      end

      def validate_search_input(source, destination, class_type, travellers_count, parsed_date)
        return { status: :bad_request, message: "Source and destination are required" } if source.blank? || destination.blank?
        return { status: :bad_request, message: "Source and destination cannot be same" } if source == destination
        return { status: :unprocessable_entity, message: "Travellers count should be in between 1 to 9" } unless travellers_count.between?(1, 9)
        return { status: :bad_request, message: "Invalid departure date format" } unless parsed_date
        nil
      end
    end
  end
end
