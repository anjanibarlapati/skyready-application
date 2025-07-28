FactoryBot.define do
  factory :flight_schedule do
    association :flight
    departure_time { "10:00:00" }
    arrival_time   { "12:00:00" }
    start_date     { Time.zone.today }
    end_date       { Time.zone.today + 30 }
    recurring      { true }
  end
end
