FactoryBot.define do
  factory :flight_schedule do
    association :flight_route
    departure_time { "10:00" }
    arrival_time   { "12:00" }
    start_date     { Date.today }
    end_date       { Date.today + 10 }
    recurring      { true }
    days_of_week   { [ Date.today.wday ] }
  end
end
