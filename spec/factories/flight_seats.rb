FactoryBot.define do
  factory :flight_seat do
    association :flight_schedule
    class_type { "Economy" }
    total_seats { 100 }
    base_price { 5000 }
  end
end
