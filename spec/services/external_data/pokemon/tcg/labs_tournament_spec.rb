require 'rails_helper'

RSpec.describe ExternalData::Pokemon::Tcg::LabsTournament do
  def stub_response(code: 200, body: '{}')
    Struct.new(:code, :body, :headers, keyword_init: true).new(code:, body:, headers: {})
  end

  def tournament_body(message: sample_message)
    { ok: true, message: }.to_json
  end

  def sample_message(overrides = {})
    { name: 'International Championship New Orleans', players: 3752, format: 'standard' }.merge(overrides)
  end

  describe '.call' do
    context 'when the response has a valid players count' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: tournament_body)) }

      it 'returns the players count as an Integer' do
        expect(described_class.call(tournament_id: '0070')).to eq(3752)
      end
    end

    context 'when players arrives as a numeric string' do
      before do
        body = tournament_body(message: sample_message(players: '3752'))
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'coerces it to an Integer' do
        expect(described_class.call(tournament_id: '0070')).to eq(3752)
      end
    end

    context 'when a client is injected' do
      it 'uses the injected client instead of building its own' do
        client = instance_double(ExternalData::JsonApiClient, get_json: JSON.parse(tournament_body))

        described_class.call(tournament_id: '0070', client:)

        expect(client).to have_received(:get_json).with(
          path: described_class::TOURNAMENT_PATH,
          query: { id: '0070', division: described_class::DIVISION }
        )
      end
    end

    context 'when composing the request' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: tournament_body)) }

      it 'requests the mew tournament endpoint with the given id and a fixed division' do
        described_class.call(tournament_id: '0070')

        expect(HTTParty).to have_received(:get).with(
          'https://mew.limitlesstcg.com/labs/data/tcg/tournament',
          hash_including(query: { id: '0070', division: 'MA' })
        )
      end
    end

    context 'when players is missing from the message' do
      before do
        body = tournament_body(message: sample_message(players: nil))
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'returns nil instead of raising' do
        expect(described_class.call(tournament_id: '0070')).to be_nil
      end
    end

    context 'when players is not numeric' do
      before do
        body = tournament_body(message: sample_message(players: 'unknown'))
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'returns nil instead of raising' do
        expect(described_class.call(tournament_id: '0070')).to be_nil
      end
    end

    context 'when players is zero or negative' do
      before do
        body = tournament_body(message: sample_message(players: 0))
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'returns nil - not a meaningful field size' do
        expect(described_class.call(tournament_id: '0070')).to be_nil
      end
    end

    context 'when the message key is missing entirely' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: { ok: false }.to_json)) }

      it 'returns nil instead of raising' do
        expect(described_class.call(tournament_id: '0070')).to be_nil
      end
    end
  end
end
