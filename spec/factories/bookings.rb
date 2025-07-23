FactoryBot.define do
  factory :booking do
    association :flight_schedule
    flight_date { Date.today }
    class_type { "Economy" }
    available_seats { 90 }
  end
end
