module Api
  module V1
    class FlightsBookingController < Api::BaseController
      def confirm_booking
        flight_params = extract_flight_params(params[:flight])
        return render_error(:bad_request, "Flight data is required") unless flight_params

        error = validate_flight_booking_input(flight_params)
        return render_error(error[:status], error[:message]) if error

        begin
          parsed_date = Time.zone.parse(flight_params[:departure_date]).strftime("%Y-%m-%d %H:%M:%S")
        rescue ArgumentError
          return render_error(:bad_request, "Invalid departure date format")
        end

        is_success = FlightBookingService.book_seats(
          flight_params[:flight_number],
          parsed_date,
          flight_params[:class_type],
          flight_params[:travellers_count]
        )

        if is_success
          render json: { message: "Booking confirmed" }, status: :ok
        else
          render_error(:conflict, "Booking failed. Please try again or select a different flight")
        end
      rescue => e
        render_error(:internal_server_error, "Failed to book. Please try again later")
      end

      private

      def extract_flight_params(flight)
        return nil unless flight.present?

        flight_number    = flight[:flight_number]&.strip
        departure_date   = flight[:departure_date]
        class_type       = (flight[:class_type] || "Economy").strip
        travellers_count = flight[:travellers_count].to_i
        travellers_count = 1 if travellers_count <= 0


        valid_classes = [ "Economy", "Second Class", "First Class" ]
        class_type = "Economy" unless valid_classes.include?(class_type)

        {
          flight_number: flight_number,
          departure_date: departure_date,
          class_type: class_type,
          travellers_count: travellers_count
        }
      end

      def validate_flight_booking_input(flight)
        return { status: :unprocessable_entity, message: "Flight data is required" } if flight[:flight_number].blank? || flight[:departure_date].blank? || flight[:travellers_count].blank?

        unless flight[:travellers_count].between?(1, 9)
          return { status: :unprocessable_entity, message: "Travelers count should be between 1 and 9" }
        end

        nil
      end
    end
  end
end
