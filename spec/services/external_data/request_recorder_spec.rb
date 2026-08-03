require 'rails_helper'

module ExternalData

  RSpec.describe RequestRecorder do
    def fetch_outcome(records_processed:, requestable: nil)
      Struct.new(:records_processed, :requestable, keyword_init: true).new(records_processed:, requestable:)
    end

    describe '.call' do
      let(:game) { create(:game) }
      let(:tournament) { create(:tournament, game:) }

      before { freeze_time }

      context 'when the fetch succeeds' do
        subject(:record) do
          described_class.call(game:, kind: :tournaments, source_url: 'https://example.com/tournaments') do |request|
            travel(5.seconds)
            request.response_body = { 'players' => [] }
            fetch_outcome(records_processed: 12, requestable: tournament)
          end
        end

        it 'records the fetch as a success' do
          expect(record.status).to eq('success')
        end

        it 'records how many records were processed' do
          expect(record.records_processed).to eq(12)
        end

        it 'records how long the fetch took' do
          expect(record.duration_seconds).to eq(5)
        end

        it 'records the fetch against its game' do
          expect(record.game).to eq(game)
        end

        it 'records the fetch against its kind' do
          expect(record.kind).to eq('tournaments')
        end

        it 'records the fetch against its source url' do
          expect(record.source_url).to eq('https://example.com/tournaments')
        end

        it 'records the fetch against its requestable' do
          expect(record.requestable).to eq(tournament)
        end

        it 'persists the response body the block set' do
          expect(record.reload.response_body).to eq({ 'players' => [] })
        end

        it 'returns the recorded request to the caller' do
          expect(record).to eq(ExternalRequest.last)
        end
      end

      context 'when the block returns a fetch result with no requestable' do
        subject(:record) do
          described_class.call(game:, kind: :tournaments, source_url: 'https://example.com/tournaments') do |_r|
            fetch_outcome(records_processed: 3)
          end
        end

        it 'leaves the requestable nil' do
          expect(record.requestable).to be_nil
        end
      end

      context 'when the block returns a value that fails the success validation' do
        subject(:record) do
          described_class.call(game:, kind: :tournaments, source_url: 'https://example.com/tournaments') do |_r|
            travel(4.seconds)
            fetch_outcome(records_processed: -1)
          end
        end

        it 'records the fetch as a failure' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.status).to eq('failure')
        end

        it 'stores the validation error' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.error).to include('RecordInvalid')
        end

        it 'records when the request finished' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.finished_at).not_to be_nil
        end

        it 'reraises the validation error to the caller' do
          expect { record }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context 'when the block mutates the request into an invalid state and raises' do
        subject(:record) do
          described_class.call(game:, kind: :players, source_url: 'https://example.com/players') do |request|
            travel(2.seconds)
            request.started_at = nil
            raise IOError, 'connection reset by peer'
          end
        end

        it 'records the fetch as a failure despite the invalid in-memory state' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.status).to eq('failure')
        end

        it 'stores the original error, not a bookkeeping validation error' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.error).to include('connection reset by peer')
        end

        it 'records when the request finished' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.finished_at).not_to be_nil
        end

        it 'reraises the original error to the caller, not a validation error' do
          expect { record }.to raise_error(IOError, /connection reset/)
        end
      end

      context 'when the fetch raises' do
        subject(:record) do
          described_class.call(game:, kind: :players, source_url: 'https://example.com/players') do |request|
            travel(3.seconds)
            request.response_body = { 'raw' => 'not found' }
            raise ArgumentError, 'boom'
          end
        end

        it 'records the fetch as a failure' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.status).to eq('failure')
        end

        it 'stores the error class and message' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.error).to eq('ArgumentError: boom')
        end

        it 'records how long the fetch ran before failing' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.duration_seconds).to eq(3)
        end

        it 'persists the response body set before the raise' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.response_body).to eq({ 'raw' => 'not found' })
        end

        it 'reraises the error to the caller' do
          expect { record }.to raise_error(ArgumentError, 'boom')
        end
      end

      context 'when the block sets a response body that fails to serialize and raises' do
        subject(:record) do
          described_class.call(game:, kind: :players, source_url: 'https://example.com/players') do |request|
            travel(6.seconds)
            request.response_body = { 'raw' => "\xFF\xFE".dup.force_encoding('UTF-8') }
            raise ArgumentError, 'boom'
          end
        end

        it 'still closes the row as a failure instead of leaving it running' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.status).to eq('failure')
        end

        it 'stores the original error, not a JSON serialization error' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.error).to eq('ArgumentError: boom')
        end

        it 'records when the request finished' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.finished_at).not_to be_nil
        end

        it 'does not persist the unserializable response body' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.response_body).to be_nil
        end

        it 'reraises the original error to the caller, not the JSON serialization error' do
          expect { record }.to raise_error(ArgumentError, 'boom')
        end
      end

      context 'when the block sets a response body that fails to serialize but the fetch otherwise succeeds' do
        subject(:record) do
          described_class.call(game:, kind: :players, source_url: 'https://example.com/players') do |request|
            travel(7.seconds)
            request.response_body = { 'raw' => "\xFF\xFE".dup.force_encoding('UTF-8') }
            fetch_outcome(records_processed: 9)
          end
        end

        it 'still closes the row instead of leaving it running' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.status).to eq('failure')
        end

        it 'stores the JSON serialization error that mark_success hit' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.error).to include('JSON::GeneratorError')
        end

        it 'records when the request finished' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.finished_at).not_to be_nil
        end

        it 'does not persist the unserializable response body' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.response_body).to be_nil
        end

        it 'reraises the serialization error to the caller' do
          expect { record }.to raise_error(JSON::GeneratorError)
        end
      end

      context 'when the block returns a bare value with no records_processed method' do
        subject(:record) do
          described_class.call(game:, kind: :players, source_url: 'https://example.com/players') do |_request|
            travel(1.second)
            5
          end
        end

        it 'records the fetch as a failure instead of leaving it stranded' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.status).to eq('failure')
        end

        it 'stores a NoMethodError describing the missing records_processed method' do
          suppress(StandardError) { record }

          expect(ExternalRequest.last.error).to include('NoMethodError')
        end

        it 'reraises a NoMethodError to the caller' do
          expect { record }.to raise_error(NoMethodError)
        end
      end
    end
  end

end
