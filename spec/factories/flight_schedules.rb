FactoryBot.define do
  factory :flight_schedule do
    association :flight

    transient do
      flight_date { Time.zone.today + 1 }
      flight_departure_time { "10:00:00" }
      flight_arrival_time { "12:00:00" }
    end

    departure_time { Time.zone.parse("#{flight_date} #{flight_departure_time}") }
    arrival_time { Time.zone.parse("#{flight_date} #{flight_arrival_time}") }

    start_date { flight_date }
    end_date { flight_date + 30 }
    recurring { true }
  end
end
