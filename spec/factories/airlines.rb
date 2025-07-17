FactoryBot.define do
  factory :airline do
    sequence(:name) { |n| "Airline #{n}" }
  end
end