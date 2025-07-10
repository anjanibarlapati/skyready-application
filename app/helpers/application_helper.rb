module ApplicationHelper
  def journey_duration(departure_date, departure_time, arrival_date, arrival_time)
    begin
      parsed_departure_date = Date.strptime(departure_date, "%Y-%m-%d")
      parsed_arrival_date = Date.strptime(arrival_date, "%Y-%m-%d")

      start_time = Time.parse("#{parsed_departure_date} #{departure_time}")
      end_time = Time.parse("#{parsed_arrival_date} #{arrival_time}")

      duration_seconds = end_time - start_time
      return "Invalid duration" if duration_seconds <= 0

      total_minutes = (duration_seconds / 60).to_i
      days = total_minutes / (24 * 60)
      hours = (total_minutes % (24 * 60)) / 60
      minutes = total_minutes % 60

      [].tap do |parts|
        parts << "#{days}d" if days > 0
        parts << "#{hours}h" if hours > 0
        parts << "#{minutes}m" if minutes > 0
      end.join(" ")

    rescue ArgumentError
      "Duration not available"
    end
  end
end
