module Api
  module V1
    class FlightsBookingController < Api::BaseController
      def confirm_booking
        flight_params = extract_flight_params(params[:flight])
        return render_error(:bad_request, "Flight data is required") unless flight_params

        error = validate_flight_booking_input(flight_params)
        return render_error(error[:status], error[:message]) if error

        begin
          parsed_date = Time.zone.parse(flight_params[:departure_date])
        rescue ArgumentError
          return render_error(:bad_request, "Invalid departure date format") unless parsed_date
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

      def confirm_round_trip_booking
        round_trip_params = extract_round_trip_params(params[:data])
        return render_error(:bad_request, "Flight data is required") unless round_trip_params

        error = validate_round_trip_booking_input(round_trip_params)
        return render_error(error[:status], error[:message]) if error

        departure_dt = Time.zone.parse(round_trip_params[:departure_date]) rescue nil
        return_dt    = Time.zone.parse(round_trip_params[:return_date]) rescue nil

        unless departure_dt && return_dt
          return render_error(:bad_request, "Invalid departure or/and return date formats")
        end

        is_success = FlightBookingService.book_round_trip_seats(
          round_trip_params[:departure_flight_number],
          departure_dt,
          round_trip_params[:return_flight_number],
          return_dt,
          round_trip_params[:class_type],
          round_trip_params[:travellers_count]
        )

        if is_success
          render json: { message: "Round-trip booking confirmed" }, status: :ok
        else
          render_error(:conflict, "Booking failed. Try again or choose different flights.")
        end
      rescue => e
        Rails.logger.error("Round-trip booking error: #{e.message}")
        render_error(:internal_server_error, "Failed to book round-trip. Please try again later")
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

      def extract_round_trip_params(data)
        return nil unless data.present?

        travellers_count = data[:travellers_count].to_i
        travellers_count = 1 if travellers_count <= 0

        class_type = (data[:class_type] || "Economy").strip
        valid_classes = ["Economy", "Second Class", "First Class"]
        class_type = "Economy" unless valid_classes.include?(class_type)

        {
          departure_flight_number: data[:departure_flight_number]&.strip,
          departure_date: data[:departure_date],
          return_flight_number: data[:return_flight_number]&.strip,
          return_date: data[:return_date],
          class_type: class_type,
          travellers_count: travellers_count
        }
      end

      def validate_round_trip_booking_input(data)
        required_fields = %i[
          departure_flight_number departure_date
          return_flight_number return_date travellers_count
        ]
        missing = required_fields.any? { |key| data[key].blank? }
        return { status: :unprocessable_entity, message: "All fields are required" } if missing

        unless data[:travellers_count].between?(1, 9)
          return { status: :unprocessable_entity, message: "Travelers count should be between 1 and 9" }
        end

        nil
      end
    end
  end
end
