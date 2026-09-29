require 'rails_helper'

module ExternalData

  RSpec.describe RetentionJob do
    subject(:run_job) { described_class.perform_now }

    let(:game) { create(:game) }

    def aged_request(age:, owner: game, **attributes)
      travel_to(age.ago) { create(:external_request, game: owner, **attributes) }
    end

    describe '#perform' do
      context 'when a request is inside the days the log keeps an entry' do
        let(:request) { aged_request(age: (described_class::RETENTION_DAYS - 1).days) }

        before do
          request
          run_job
        end

        it 'keeps the row in the database' do
          expect(ExternalRequest.find_by(id: request.id)).to be_present
        end
      end

      context 'when a request sits exactly on the edge of the days the log keeps an entry' do
        let(:request) { aged_request(age: described_class::RETENTION_DAYS.days) }

        before do
          freeze_time
          request
          run_job
        end

        it 'keeps the row in the database' do
          expect(ExternalRequest.find_by(id: request.id)).to be_present
        end
      end

      context 'when a request is one second past the edge of the days the log keeps an entry' do
        let(:request) { aged_request(age: described_class::RETENTION_DAYS.days + 1.second) }

        before do
          freeze_time
          request
          run_job
        end

        it 'removes the row from the database' do
          expect(ExternalRequest.with_discarded.exists?(id: request.id)).to be(false)
        end
      end

      context 'when a request is discarded' do
        let(:request) { create(:external_request, :discarded, game:) }

        before do
          request
          run_job
        end

        it 'removes the row from the database' do
          expect(ExternalRequest.with_discarded.find_by(id: request.id)).to be_nil
        end
      end

      context 'when a request is not discarded' do
        let(:request) { aged_request(age: 1.hour) }

        before do
          request
          run_job
        end

        it 'keeps the row in the database' do
          expect(ExternalRequest.find_by(id: request.id)).to be_present
        end
      end
    end
  end

end
