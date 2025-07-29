module Api
  module V1
    class FlightsBookingController < Api::BaseController
      VALID_CLASSES = ["Economy", "Second Class", "First Class"].freeze
      DEFAULT_CLASS = "Economy".freeze
      MIN_TRAVELLERS = 1
      MAX_TRAVELLERS = 9

      def confirm_booking
        flight_params = extract_flight_params(params[:flight])
        return render_error(:bad_request, "Flight data is required") if flight_params.blank?

        error = validate_flight_booking_input(flight_params)
        return render_error(error[:status], error[:message]) if error

        parsed_date = parse_departure_date!(flight_params[:departure_date])
        if(parsed_date.nil?)
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

      def confirm_round_trip_booking
        round_trip_params = extract_round_trip_params(params[:data])
        return render_error(:bad_request, "Flight data is required") if round_trip_params.blank?

        error = validate_round_trip_booking_input(round_trip_params)
        return render_error(error[:status], error[:message]) if error

        departure_dt = parse_departure_date!(round_trip_params[:departure_date])
        return_dt    = parse_departure_date!(round_trip_params[:return_date])
        if(departure_dt.nil? || return_dt.nil?)
          return render_error(:bad_request, "Invalid date format for departure or return date")
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
        render_error(:internal_server_error, "Failed to book round-trip. Please try again later")
      end

      private

      def extract_flight_params(flight)
        return nil unless flight.present?

        {
          flight_number: flight[:flight_number]&.strip,
          departure_date: flight[:departure_date],
          class_type: validate_class_type(flight[:class_type]),
          travellers_count: validate_travellers_count(flight[:travellers_count])
        }
      end

      def extract_round_trip_params(data)
        return nil unless data.present?

        {
          departure_flight_number: data[:departure_flight_number]&.strip,
          departure_date: data[:departure_date],
          return_flight_number: data[:return_flight_number]&.strip,
          return_date: data[:return_date],
          class_type: validate_class_type(data[:class_type]),
          travellers_count: validate_travellers_count(data[:travellers_count])
        }
      end

      def validate_class_type(type)
        cleaned_type = type.to_s.strip
        VALID_CLASSES.include?(cleaned_type) ? cleaned_type : DEFAULT_CLASS
      end

      def validate_travellers_count(count)
        count = count.to_i
        count >= MIN_TRAVELLERS ? count : MIN_TRAVELLERS
      end

      def validate_flight_booking_input(flight)
        return {
          status: :unprocessable_entity,
          message: "Flight data is required"
        } if flight[:flight_number].blank? || flight[:departure_date].blank? || flight[:travellers_count].blank?

        unless flight[:travellers_count].between?(MIN_TRAVELLERS, MAX_TRAVELLERS)
          return {
            status: :unprocessable_entity,
            message: "Travellers count should be between #{MIN_TRAVELLERS} and #{MAX_TRAVELLERS}"
          }
        end

        nil
      end

      def validate_round_trip_booking_input(data)
        required_fields = %i[
          departure_flight_number departure_date
          return_flight_number return_date travellers_count
        ]
        missing = required_fields.any? { |key| data[key].blank? }
        return { status: :unprocessable_entity, message: "All fields are required" } if missing

        unless data[:travellers_count].between?(MIN_TRAVELLERS, MAX_TRAVELLERS)
          return {
            status: :unprocessable_entity,
            message: "Travelers count should be between #{MIN_TRAVELLERS} and #{MAX_TRAVELLERS}"
          }
        end

        nil
      end

      def parse_departure_date!(input)
        parsed = Time.zone.parse(input) rescue nil
        parsed
      end
    end
  end
end