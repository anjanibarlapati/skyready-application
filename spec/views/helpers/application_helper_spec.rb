require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#journey_duration' do
    context 'with valid input' do
      it 'returns correct duration for same day journey' do
        expect(helper.journey_duration('2025-07-10', '10:00', '2025-07-10', '12:45')).to eq('2h 45m')
      end

      it 'returns correct duration for multi-day journey' do
        expect(helper.journey_duration('2025-07-10', '23:00', '2025-07-12', '01:15')).to eq('1d 2h 15m')
      end

      it 'returns only hours and minutes if days is 0' do
        expect(helper.journey_duration('2025-07-10', '09:00', '2025-07-10', '10:15')).to eq('1h 15m')
      end

      it 'returns only minutes if hours and days are 0' do
        expect(helper.journey_duration('2025-07-10', '10:00', '2025-07-10', '10:05')).to eq('5m')
      end

      it 'returns only hours if minutes and days are 0' do
        expect(helper.journey_duration('2025-07-10', '08:00', '2025-07-10', '10:00')).to eq('2h')
      end
    end

    context 'with invalid input' do
      it 'returns "Invalid duration" if arrival is before departure' do
        expect(helper.journey_duration('2025-07-10', '14:00', '2025-07-10', '13:00')).to eq('Invalid duration')
      end

      it 'returns "Duration not available" for unparseable date/time' do
        expect(helper.journey_duration('invalid-date', '10:00', '2025-07-10', '12:00')).to eq('Duration not available')
      end

      it 'returns "Invalid duration" for zero-length journey' do
        expect(helper.journey_duration('2025-07-10', '10:00', '2025-07-10', '10:00')).to eq('Invalid duration')
      end
    end
  end
end
