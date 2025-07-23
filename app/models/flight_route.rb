class FlightRoute < ApplicationRecord
  belongs_to :airline
  has_many :flights, dependent: :destroy

  validates :source, :destination, presence: true
  validates :airline_id, uniqueness: {
    scope: [ :source, :destination ],
    message: "already has a route between this source and destination"
  }
end
