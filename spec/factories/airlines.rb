FactoryBot.define do
  factory :airline do
    sequence(:name) { |n| "Test Airline #{n}" }
  end
end
