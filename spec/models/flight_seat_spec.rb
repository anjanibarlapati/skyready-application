require 'rails_helper'

RSpec.describe FlightSeat, type: :model do
  describe 'associations' do
    it { should belong_to(:flight) }
  end

  describe 'validations' do
    it { should validate_presence_of(:class_type) }
    it { should validate_presence_of(:total_seats) }
    it { should validate_presence_of(:available_seats) }
    it { should validate_presence_of(:base_price) }

    it do
      should validate_inclusion_of(:class_type).
        in_array([ "Economy", "First Class", "Second Class" ])
    end
  end
end
