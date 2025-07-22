class Airline < ApplicationRecord
  self.primary_key = "name"

  has_many :flight_routes, foreign_key: :airline_name, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
