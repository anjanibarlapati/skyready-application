class Airline < ApplicationRecord
  has_many :flight_routes, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
