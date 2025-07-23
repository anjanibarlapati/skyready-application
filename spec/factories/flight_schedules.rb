FactoryBot.define do
  factory :flight_schedule do
    association :flight
    departure_time { "10:00" }
    arrival_time { "12:00" }
    start_date { Date.today }
    end_date { Date.today + 30 }
    recurring { true }
  end
end
