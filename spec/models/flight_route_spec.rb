require 'rails_helper'

RSpec.describe FlightRoute, type: :model do
  describe 'associations' do
    it {
      should belong_to(:airline)
        .with_foreign_key(:airline_name)
        .class_name('Airline')
    }
  end

  describe 'validations' do
    it { should validate_presence_of(:flight_number) }
    it { should validate_presence_of(:airline_name) }
    it { should validate_presence_of(:source) }
    it { should validate_presence_of(:destination) }

    context 'uniqueness validation' do
      before do
        create(:airline, name: "Indigo")
        create(:flight_route,
          flight_number: "AI202",
          source: "Delhi",
          destination: "Mumbai",
          airline_name: "Indigo"
        )
      end

      it 'is invalid when flight_number with same source and destination already exists' do
        duplicate = build(:flight_route,
          flight_number: "AI202",
          source: "Delhi",
          destination: "Mumbai",
          airline_name: "Indigo"
        )
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:flight_number]).to include("with this source and destination already exists")
      end

      it 'is valid when flight_number is same but source or destination is different' do
        different_route = build(:flight_route,
          flight_number: "AI202",
          source: "Chennai",
          destination: "Mumbai",
          airline_name: "Indigo"
        )
        expect(different_route).to be_valid
      end
    end
  end
end
