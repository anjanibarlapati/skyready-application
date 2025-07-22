FactoryBot.define do
  factory :booking do
    association :flight_schedule
    class_type { "Economy" }
    flight_date { Date.today }
    available_seats { 20 }
  end
end
