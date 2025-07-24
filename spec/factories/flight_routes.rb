FactoryBot.define do
  factory :flight_route do
    association :airline
    source { "Mumbai" }
    destination { "Delhi" }
  end
end
