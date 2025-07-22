require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe 'associations' do
    it { should belong_to(:flight_schedule) }
  end

  describe 'validations' do
    it { should validate_presence_of(:flight_date) }
    it { should validate_presence_of(:class_type) }
    it { should validate_presence_of(:available_seats) }

    it {
      should validate_inclusion_of(:class_type)
        .in_array(Booking::CLASS_TYPES)
    }

    it {
      should validate_numericality_of(:available_seats)
        .only_integer
        .is_greater_than_or_equal_to(0)
    }
  end
end
