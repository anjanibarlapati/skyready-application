class Flight < ApplicationRecord
  belongs_to :airline
  has_many :flight_seats, dependent: :destroy

  validates :flight_number, :source, :destination, :departure_datetime, :arrival_datetime, presence: true
end
