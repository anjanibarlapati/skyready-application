require 'rails_helper'

RSpec.describe Flight, type: :model do
  describe 'associations' do
    it { should belong_to(:airline) }
    it { should have_many(:flight_seats).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:flight_number) }
    it { should validate_presence_of(:source) }
    it { should validate_presence_of(:destination) }
    it { should validate_presence_of(:departure_datetime) }
    it { should validate_presence_of(:arrival_datetime) }
  end
end
