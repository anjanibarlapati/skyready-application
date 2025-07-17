require 'rails_helper'

RSpec.describe Airline, type: :model do
  describe 'associations' do
    it { should have_many(:flights).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }

    it 'validates uniqueness of name' do
      create(:airline, name: "IndiGoo")
      duplicate = build(:airline, name: "IndiGoo")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end
end
