FactoryBot.define do
  factory :flight_schedule_day do
    association :flight_schedule
    day_of_week { 0 }
  end
end
