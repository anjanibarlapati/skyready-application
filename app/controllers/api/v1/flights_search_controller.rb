module Api
  module V1
    class FlightsSearchController < Api::BaseController
      VALID_CLASSES = ["Economy", "Second Class", "First Class"].freeze
      MIN_TRAVELLERS = 1
      MAX_TRAVELLERS = 9

      def search
        source, destination, class_type, travellers_count, parsed_date = extract_search_params

        error = validate_search_input(source, destination, class_type, travellers_count, parsed_date)
        return render_error(error[:status], error[:message]) if error

        result = FlightSearchService.search(source, destination, parsed_date, travellers_count, class_type)
        return render_error(:not_found, "Flights are not operating between given source and destination") unless result[:found_route]
        return render_error(:conflict, "Flights with #{class_type.downcase} are not available between the selected source and destination on selected date") unless result[:found_class_type]
        return render_error(:conflict, "No flights available on the selected date") unless result[:found_date]
        return render_error(:conflict, "No seats available for #{class_type.downcase} class on selected date") unless result[:seats_available]

        render json: { flights: result[:flights] }, status: :ok
      rescue => e
        render_error(:internal_server_error, "Something went wrong while searching flights. Please try again.")
      end

      private

      def parse_class_type(input)
        normalized_input = input.to_s.strip
        VALID_CLASSES.include?(normalized_input) ? normalized_input : "Economy"
      end

      def extract_search_params
        source      = params[:source]&.strip
        destination = params[:destination]&.strip
        class_type  = parse_class_type(params[:class_type])
        travellers_count = [params[:travellers_count].to_i, MIN_TRAVELLERS].max
        departure_date   = parse_date(params[:departure_date])

        [ source, destination, class_type, travellers_count, departure_date ]
      end

      
      def parse_date(input)
        return Date.today if input.blank?
        Date.parse(input) rescue nil
      end

      def validate_search_input(source, destination, class_type, travellers_count, parsed_datetime)
        return { status: :bad_request, message: "Source and destination are required" } if source.blank? || destination.blank?
        return { status: :bad_request, message: "Source and destination cannot be the same" } if source.downcase == destination.downcase
        return { status: :unprocessable_entity, message: "Travellers count must be between 1 to 9" } unless travellers_count.between?(MIN_TRAVELLERS, MAX_TRAVELLERS)
        return { status: :bad_request, message: "Invalid departure date format" } unless parsed_datetime
        nil
      end
    end
  end
end
