require 'rails_helper'

RSpec.describe ExternalData::Synthetic::ResultsVerifier do
  subject(:verifier) { described_class.new }

  describe 'the production guard' do
    context 'when Rails.env is production' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production')) }

      it 'raises instead of returning a usable verifier' do
        expect { described_class.new }.to raise_error(ExternalData::Exception, /must never run/)
      end
    end

    context 'when Rails.env is not production' do
      it 'does not raise' do
        expect { described_class.new }.not_to raise_error
      end
    end
  end

  describe '#call' do
    context 'when given a blank id' do
      it 'returns a blank result, so :not_found stays reachable' do
        expect(verifier.call('')).to be_blank
      end
    end

    context 'when given a real-looking id' do
      it 'returns a positive integer' do
        expect(verifier.call('0070')).to be_a(Integer).and be_positive
      end

      it 'returns the same count for the same id every time' do
        first_call = verifier.call('0070')

        expect(verifier.call('0070')).to eq(first_call)
      end

      it 'returns a different count for a different id' do
        expect(verifier.call('0070')).not_to eq(verifier.call('0071'))
      end
    end
  end
end
