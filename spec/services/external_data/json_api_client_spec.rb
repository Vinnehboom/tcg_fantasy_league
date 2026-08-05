require 'rails_helper'

module ExternalData

  RSpec.describe JsonApiClient do
    def stub_response(code: 200, body: '{}', headers: {})
      Struct.new(:code, :body, :headers, keyword_init: true).new(code:, body:, headers:)
    end

    let(:retry_policy) { RetryPolicy.new(timeout: 7) }
    let(:client) { described_class.new(base_uri: 'https://example.com', retry_policy:) }

    describe '#get_json' do
      context 'when the request succeeds' do
        before { allow(HTTParty).to receive(:get).and_return(stub_response(body: '{"name":"Ash"}')) }

        it 'returns the parsed JSON payload' do
          expect(client.get_json(path: '/players/1')).to eq('name' => 'Ash')
        end
      end

      context 'when composing the request URL' do
        before { allow(HTTParty).to receive(:get).and_return(stub_response) }

        it 'concatenates the base_uri and the path' do
          client.get_json(path: '/players/1')

          expect(HTTParty).to have_received(:get).with('https://example.com/players/1', anything)
        end
      end

      context 'when a query is given' do
        before { allow(HTTParty).to receive(:get).and_return(stub_response) }

        it 'passes the query through to the request' do
          client.get_json(path: '/players', query: { region: 'na' })

          expect(HTTParty).to have_received(:get).with(anything, hash_including(query: { region: 'na' }))
        end
      end

      context 'when no query is given' do
        before { allow(HTTParty).to receive(:get).and_return(stub_response) }

        it 'omits the query option from the request' do
          client.get_json(path: '/players')

          expect(HTTParty).to have_received(:get).with(anything, hash_excluding(:query))
        end
      end

      context 'when the client has a configured timeout' do
        before { allow(HTTParty).to receive(:get).and_return(stub_response) }

        it 'applies the retry_policy timeout to the request' do
          client.get_json(path: '/players')

          expect(HTTParty).to have_received(:get).with(anything, hash_including(timeout: 7))
        end
      end

      context 'when the response is not a 200' do
        before { allow(HTTParty).to receive(:get).and_return(stub_response(code: 404)) }

        it 'raises an HttpError' do
          expect { client.get_json(path: '/players/1') }.to raise_error(described_class::HttpError)
        end
      end

      context 'when an HttpError is raised' do
        before { allow(HTTParty).to receive(:get).and_return(stub_response(code: 404)) }

        it 'carries the response status and the request URL' do
          error = nil
          begin
            client.get_json(path: '/players/1')
          rescue described_class::HttpError => e
            error = e
          end

          expect(error).to have_attributes(status: 404, url: 'https://example.com/players/1')
        end
      end

      context 'when the same client is reused for a second call' do
        it 'issues each call against its own path on the shared host' do
          urls = []
          allow(HTTParty).to receive(:get) do |url, **_options|
            urls << url
            stub_response
          end

          client.get_json(path: '/players/1')
          client.get_json(path: '/players/2')

          expect(urls).to eq(%w[https://example.com/players/1 https://example.com/players/2])
        end
      end
    end
  end

end
