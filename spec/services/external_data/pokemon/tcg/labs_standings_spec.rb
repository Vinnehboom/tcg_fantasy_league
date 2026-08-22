require 'rails_helper'

RSpec.describe ExternalData::Pokemon::Tcg::LabsStandings do
  def stub_response(code: 200, body: '{}')
    Struct.new(:code, :body, :headers, keyword_init: true).new(code:, body:, headers: {})
  end

  def standings_body(message: [sample_entry])
    { ok: true, message: }.to_json
  end

  def sample_entry(overrides = {})
    identity_fields.merge(result_fields).merge(unmapped_fields).merge(overrides)
  end

  def identity_fields
    { player_id: 1, name: 'Test Player One', country: 'US', placement: 1 }
  end

  def result_fields
    { drop_round: nil, late: false, dqed: false, dropped: false }
  end

  def unmapped_fields
    { tp_id: 'abc123', points: 3, wins: 8, losses: 1, ties: 0, opw: '0.62500000', opw2: '0.58333333', day2: true,
      topcut: true, decklist: 'https://limitlesstcg.com/decks/list/abc123', deck_id: 'charizard-ex',
      deck_name: 'Charizard ex', icons: %w[fire] }
  end

  def other_sample_entry(overrides = {})
    sample_entry({ player_id: 2, name: 'Test Player Two', country: 'CA', placement: 2 }.merge(overrides))
  end

  describe '.call' do
    context 'when the response has a valid entry' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: standings_body)) }

      it 'maps the entry to an ExternalData::Result with the mew external_id format' do
        result = described_class.call(tournament_id: '0070').first

        expect(result.player_external_id).to eq('/players/1')
      end

      it 'maps name, country and placement directly' do
        result = described_class.call(tournament_id: '0070').first

        expect(result).to have_attributes(player_name: 'Test Player One', player_country: 'US', placement: 1)
      end
    end

    context 'when the response has multiple valid entries' do
      before do
        body = standings_body(message: [sample_entry, other_sample_entry])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'maps every entry to its own ExternalData::Result' do
        results = described_class.call(tournament_id: '0070')

        expect(results.length).to eq(2)
      end

      it 'preserves each entry\'s own attributes independently' do
        results = described_class.call(tournament_id: '0070')

        expect(results).to contain_exactly(
          have_attributes(player_external_id: '/players/1', player_name: 'Test Player One', placement: 1),
          have_attributes(player_external_id: '/players/2', player_name: 'Test Player Two', placement: 2)
        )
      end
    end

    context 'when a client is injected' do
      it 'uses the injected client instead of building its own' do
        client = instance_double(ExternalData::JsonApiClient, get_json: JSON.parse(standings_body))

        described_class.call(tournament_id: '0070', client:)

        expect(client).to have_received(:get_json).with(
          path: described_class::STANDINGS_PATH,
          query: { tournamentId: '0070', division: described_class::DIVISION }
        )
      end
    end

    context 'when composing the request' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: standings_body)) }

      it 'requests the mew standings endpoint with the given tournament and a fixed division' do
        described_class.call(tournament_id: '0070')

        expect(HTTParty).to have_received(:get).with(
          'https://mew.limitlesstcg.com/labs/data/tcg/standings',
          hash_including(query: { tournamentId: '0070', division: 'MA' })
        )
      end
    end

    context 'when an entry is missing player_id' do
      before do
        body = standings_body(message: [sample_entry(player_id: nil), sample_entry])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'skips the incomplete entry without raising' do
        expect(described_class.call(tournament_id: '0070').length).to eq(1)
      end
    end

    context 'when an entry is missing name' do
      before do
        body = standings_body(message: [sample_entry(name: nil), sample_entry])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'skips the incomplete entry without raising' do
        expect(described_class.call(tournament_id: '0070').length).to eq(1)
      end
    end

    context 'when an entry is missing placement' do
      before do
        body = standings_body(message: [sample_entry(placement: nil), sample_entry])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'skips the incomplete entry without raising' do
        expect(described_class.call(tournament_id: '0070').length).to eq(1)
      end
    end

    context 'when an entry carries unmapped fields (points, wins, opw, decklist, icons, ...)' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: standings_body)) }

      it 'maps the entry without raising' do
        expect { described_class.call(tournament_id: '0070') }.not_to raise_error
      end
    end

    context 'when an entry has dropped: true' do
      before do
        body = standings_body(message: [sample_entry(dropped: true), sample_entry])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'excludes the dropped entry from the returned results' do
        results = described_class.call(tournament_id: '0070')

        expect(results.map(&:placement)).to eq([1])
      end
    end

    context 'when an entry has dqed: true' do
      before do
        body = standings_body(message: [sample_entry(dqed: true), sample_entry])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'excludes the disqualified entry from the returned results' do
        results = described_class.call(tournament_id: '0070')

        expect(results.map(&:placement)).to eq([1])
      end
    end

    context 'when dropped/dqed arrive as numeric-boolean 0/1 rather than JSON booleans' do
      before do
        body = standings_body(message: [sample_entry(dropped: 0, dqed: 0), sample_entry(dropped: 1)])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'treats 0 as false and 1 as true, not as Ruby truthiness would' do
        results = described_class.call(tournament_id: '0070')

        expect(results.map(&:placement)).to eq([1])
      end
    end

    context 'when dropped/dqed arrive as the strings "0"/"false" rather than JSON booleans' do
      before do
        body = standings_body(message: [sample_entry(dropped: '0', dqed: 'false'), sample_entry(dropped: 'true')])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'treats "0"/"false" as false and "true" as true, not as Ruby truthiness would' do
        results = described_class.call(tournament_id: '0070')

        expect(results.map(&:placement)).to eq([1])
      end
    end

    context 'when the message array is empty' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: standings_body(message: []))) }

      it 'returns an empty array' do
        expect(described_class.call(tournament_id: '0070')).to eq([])
      end
    end

    context 'when the response has no message key at all' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: { ok: false }.to_json)) }

      it 'returns an empty array' do
        expect(described_class.call(tournament_id: '0070')).to eq([])
      end
    end
  end

  describe '.entrant_count' do
    context 'when every entry is a normal, non-dropped result' do
      before do
        body = standings_body(message: [sample_entry, other_sample_entry])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'counts every entry in the raw response' do
        expect(described_class.entrant_count(tournament_id: '0070')).to eq(2)
      end
    end

    context 'when some entries are dropped or disqualified' do
      before do
        body = standings_body(message: [sample_entry(dropped: true), sample_entry(dqed: true), sample_entry])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'still counts them - they registered and played, they just did not finish' do
        expect(described_class.entrant_count(tournament_id: '0070')).to eq(3)
      end
    end

    context 'when an entry is missing fields that would exclude it from .call' do
      before do
        body = standings_body(message: [sample_entry(player_id: nil), sample_entry])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'still counts the malformed entry - it is a raw entrant count, not a valid-Result count' do
        expect(described_class.entrant_count(tournament_id: '0070')).to eq(2)
      end
    end

    context 'when the message array is empty' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: standings_body(message: []))) }

      it 'returns zero' do
        expect(described_class.entrant_count(tournament_id: '0070')).to eq(0)
      end
    end

    context 'when a client is injected' do
      it 'uses the injected client instead of building its own' do
        client = instance_double(ExternalData::JsonApiClient, get_json: JSON.parse(standings_body))

        described_class.entrant_count(tournament_id: '0070', client:)

        expect(client).to have_received(:get_json).with(
          path: described_class::STANDINGS_PATH,
          query: { tournamentId: '0070', division: described_class::DIVISION }
        )
      end
    end
  end
end
