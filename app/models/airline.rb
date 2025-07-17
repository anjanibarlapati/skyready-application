class Airline < ApplicationRecord
  has_many :flights, dependent: :destroy
  validates :name, presence: true, uniqueness: true
end
