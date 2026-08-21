require 'rails_helper'

RSpec.describe ExternalData::OfflineAdapter do
  subject(:adapter) { described_class.new }

  it_behaves_like 'an external data adapter'

  describe '#players' do
    it 'raises an external data exception explaining the adapter is invalid' do
      message = /the #players method was called on an invalid adapter/

      expect { adapter.players }.to raise_error(ExternalData::Exception, message)
    end
  end

  describe '#upcoming_tournaments' do
    it 'raises an external data exception explaining the adapter is invalid' do
      message = /the #upcoming_tournaments method was called on an invalid adapter/

      expect { adapter.upcoming_tournaments }.to raise_error(ExternalData::Exception, message)
    end
  end

  describe '#results' do
    it 'raises an external data exception explaining the adapter is invalid' do
      message = /the #results method was called on an invalid adapter/

      expect { adapter.results(tournament: build(:tournament)) }.to raise_error(ExternalData::Exception, message)
    end
  end
end
