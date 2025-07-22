FactoryBot.define do
  factory :flight_route do
    sequence(:flight_number) { |n| "AI#{n}" }
    source { "Delhi" }
    destination { "Mumbai" }

    association :airline
    airline_name { airline.name }
  end
end
