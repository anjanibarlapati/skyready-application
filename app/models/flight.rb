class Flight < ApplicationRecord
  belongs_to :flight_route
  has_one :airline, through: :flight_route
  has_many :flight_schedules, dependent: :destroy

  validates :flight_number, presence: true, uniqueness: true
end
