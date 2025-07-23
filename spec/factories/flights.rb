FactoryBot.define do
  factory :flight do
    association :flight_route
    sequence(:flight_number) { |n| "AI#{100 + n}" }
  end
end
