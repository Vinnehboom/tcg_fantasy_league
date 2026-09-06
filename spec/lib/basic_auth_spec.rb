require 'rails_helper'

RSpec.describe BasicAuth do
  describe '#authorized?' do
    context 'when both credentials are configured' do
      subject(:auth) { described_class.new(username: 'vinnie', password: 's3cret') }

      it 'lets the matching pair through' do
        expect(auth.authorized?(username: 'vinnie', password: 's3cret')).to be true
      end

      it 'rejects a wrong password' do
        expect(auth.authorized?(username: 'vinnie', password: 'guess')).to be false
      end

      it 'rejects a wrong username' do
        expect(auth.authorized?(username: 'stranger', password: 's3cret')).to be false
      end

      it 'rejects a request that sends no credentials at all' do
        expect(auth.authorized?(username: nil, password: nil)).to be false
      end
    end

    context 'when a credential is missing from the environment' do
      it 'rejects every request rather than leaving the site open' do
        auth = described_class.new(username: 'vinnie', password: nil)

        expect(auth.authorized?(username: 'vinnie', password: '')).to be false
      end

      it 'rejects every request when both credentials are blank' do
        auth = described_class.new(username: '', password: '')

        expect(auth.authorized?(username: '', password: '')).to be false
      end
    end
  end

  describe '.from_env' do
    it 'reads the credentials the deploy sets' do
      env = { 'BASIC_AUTH_USERNAME' => 'vinnie', 'BASIC_AUTH_PASSWORD' => 's3cret' }

      auth = described_class.from_env(env)

      expect(auth.authorized?(username: 'vinnie', password: 's3cret')).to be true
    end
  end
end
