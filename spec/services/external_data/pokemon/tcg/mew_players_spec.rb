require 'rails_helper'

RSpec.describe ExternalData::Pokemon::Tcg::MewPlayers do
  def stub_response(code: 200, body: '{}')
    Struct.new(:code, :body, :headers, keyword_init: true).new(code:, body:, headers: {})
  end

  def rankings_body(message: [sample_entry])
    { ok: true, message: }.to_json
  end

  def sample_entry(overrides = {})
    {
      player_id: 860,
      name: 'Liam Halliburton',
      country: 'US',
      points: 1675,
      finishes: '420,350,325,300,280',
      region: 'NA'
    }.merge(overrides)
  end

  describe '.all' do
    context 'when the response has a valid entry' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: rankings_body)) }

      it 'maps the entry to an ExternalData::Player with the mew external_id format' do
        player = described_class.all(season: 2026).first

        expect(player.external_id).to eq('/players/860')
      end

      it 'maps points to external_points' do
        player = described_class.all(season: 2026).first

        expect(player.external_points).to eq(1675)
      end

      it 'maps name and country directly' do
        player = described_class.all(season: 2026).first

        expect(player).to have_attributes(name: 'Liam Halliburton', country: 'US')
      end
    end

    context 'when composing the request' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: rankings_body)) }

      it 'requests the mew rankings endpoint with the given season and a fixed division' do
        described_class.all(season: 2026)

        expect(HTTParty).to have_received(:get).with(
          'https://mew.limitlesstcg.com/labs/data/tcg/rankings',
          hash_including(query: { season: 2026, division: 'MA' })
        )
      end
    end

    context 'when an entry is missing player_id' do
      before do
        body = rankings_body(message: [sample_entry(player_id: nil), sample_entry])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'skips the incomplete entry without raising' do
        expect(described_class.all(season: 2026).length).to eq(1)
      end
    end

    context 'when an entry is missing points' do
      before do
        body = rankings_body(message: [sample_entry(points: nil), sample_entry])
        allow(HTTParty).to receive(:get).and_return(stub_response(body:))
      end

      it 'skips the incomplete entry without raising' do
        expect(described_class.all(season: 2026).length).to eq(1)
      end
    end

    context 'when an entry carries unmapped fields (finishes, region)' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: rankings_body)) }

      it 'maps the entry without raising' do
        expect { described_class.all(season: 2026) }.not_to raise_error
      end
    end

    context 'when the message array is empty' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: rankings_body(message: []))) }

      it 'returns an empty array' do
        expect(described_class.all(season: 2026)).to eq([])
      end
    end

    context 'when the response has no message key at all' do
      before { allow(HTTParty).to receive(:get).and_return(stub_response(body: { ok: false }.to_json)) }

      it 'returns an empty array' do
        expect(described_class.all(season: 2026)).to eq([])
      end
    end
  end

  describe 'a mapped player, once persisted' do
    let(:game) { create(:game, base_uri: 'https://limitlesstcg.com') }

    before { allow(HTTParty).to receive(:get).and_return(stub_response(body: rankings_body)) }

    it 'still resolves the correct external_url' do
      player = described_class.all(season: 2026).first
      player.game_id = game.id

      player.save!

      persisted = Player.find_by(external_id: '/players/860', game_id: game.id)
      expect(persisted.external_url).to eq('https://limitlesstcg.com/players/860')
    end
  end
end
