require 'rails_helper'

RSpec.describe AgeGate do
  describe '.digital_consent_age_for' do
    subject { described_class.digital_consent_age_for(country_code) }

    context 'with GB' do
      let(:country_code) { 'GB' }

      it { is_expected.to eq(13) }
    end

    context 'with BE' do
      let(:country_code) { 'BE' }

      it { is_expected.to eq(13) }
    end

    context 'with FR' do
      let(:country_code) { 'FR' }

      it { is_expected.to eq(15) }
    end

    context 'with a country not in the overrides list' do
      let(:country_code) { 'US' }

      it { is_expected.to eq(16) }
    end
  end
end
