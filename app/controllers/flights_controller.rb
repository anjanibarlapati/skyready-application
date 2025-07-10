class FlightsController < ApplicationController
  def book
    @flight = params[:flight]&.to_unsafe_h
    redirect_to root_path unless @flight
  end

  def confirm
  flight = JSON.parse(params[:flight]).with_indifferent_access

  flight_number     = flight[:flight_number]
  departure_date    = flight[:departure_date]
  class_type        = flight[:class_type]
  travellers_count  = flight[:travellers_count].to_i

  success = FlightDataUpdater.reduce_seats(flight_number, departure_date, class_type, travellers_count)

  if success
    flash[:notice] = "🎉 Booking confirmed successfully!"
  else
    flash[:alert] = "⚠️ Booking failed. Please try again or select a different flight."
  end

  redirect_to root_path
end
end
