class HomeController < ApplicationController
  def index
    @flights = []
    @searched = false

    if params[:source].present? && params[:destination].present?
      @searched = true
      @flights = FlightDataReader.search(params[:source], params[:destination])
    end
  end
end
