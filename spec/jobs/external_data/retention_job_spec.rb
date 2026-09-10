require 'rails_helper'

module ExternalData

  RSpec.describe RetentionJob do
    subject(:run_job) { described_class.perform_now }

    let(:game) { create(:game) }
    let(:raw_response) { { 'players' => %w[Ash Misty] } }

    def aged_request(age:, owner: game, **attributes)
      travel_to(age.ago) { create(:external_request, game: owner, response_body: raw_response, **attributes) }
    end

    def configure_retention_hours(value, owner: game)
      create(:setting, :for_game, settingable: owner,
                                  settings: { 'retention' => { 'external_request_hours' => value } })
    end

    describe 'a request older than the retention window' do
      let(:request) { aged_request(age: 25.hours) }

      before do
        request
        run_job
      end

      it 'erases the raw response' do
        expect(request.reload.response_body).to be_nil
      end

      it 'keeps the audit record itself' do
        expect(ExternalRequest.find_by(id: request.id)).to be_present
      end

      it 'keeps the rest of the audit record readable' do
        expect(request.reload.kind).to eq('players')
      end
    end

    describe 'a request inside the retention window' do
      let(:request) { aged_request(age: 23.hours) }

      before do
        request
        run_job
      end

      it 'keeps the raw response' do
        expect(request.reload.response_body).to eq(raw_response)
      end
    end

    describe 'a discarded request' do
      let(:request) { create(:external_request, :discarded, game:, response_body: raw_response) }

      before do
        request
        run_job
      end

      it 'removes the row from the database' do
        expect(ExternalRequest.with_discarded.find_by(id: request.id)).to be_nil
      end
    end

    describe 'a request that is not discarded' do
      let(:request) { aged_request(age: 1.hour) }

      before do
        request
        run_job
      end

      it 'keeps the row in the database' do
        expect(ExternalRequest.find_by(id: request.id)).to be_present
      end
    end

    describe 'the window a game configures for itself' do
      context 'when the game allows more hours than the default' do
        let(:request) { aged_request(age: 30.hours) }

        before do
          configure_retention_hours(48)
          request
          run_job
        end

        it 'keeps the raw response' do
          expect(request.reload.response_body).to eq(raw_response)
        end
      end

      context 'when the request is older than the window the game allows' do
        let(:request) { aged_request(age: 49.hours) }

        before do
          configure_retention_hours(48)
          request
          run_job
        end

        it 'erases the raw response' do
          expect(request.reload.response_body).to be_nil
        end
      end

      context 'when the game configures a window under one hour' do
        let(:request) { aged_request(age: 30.minutes) }

        before do
          configure_retention_hours(0)
          request
          run_job
        end

        it 'holds the window at one hour and keeps the raw response' do
          expect(request.reload.response_body).to eq(raw_response)
        end
      end

      context 'when the game has settings but none for retention' do
        let(:request) { aged_request(age: 23.hours) }

        before do
          create(:setting, :for_game, settingable: game, settings: { 'scoring' => { 'base_points' => 50 } })
          request
          run_job
        end

        it 'falls back to the default window and keeps the raw response' do
          expect(request.reload.response_body).to eq(raw_response)
        end
      end

      context 'when the configured value cannot be read as a number of hours' do
        let(:request) { aged_request(age: 25.hours) }

        before do
          configure_retention_hours('whenever')
          request
          run_job
        end

        it 'falls back to the default window and erases the raw response' do
          expect(request.reload.response_body).to be_nil
        end
      end
    end

    describe 'a second game with its own window' do
      let(:other_game) { create(:game) }
      let(:request) { aged_request(age: 30.hours) }
      let(:other_request) { aged_request(age: 30.hours, owner: other_game) }

      before do
        configure_retention_hours(72, owner: other_game)
        request
        other_request
        run_job
      end

      it 'keeps the raw response the other game still allows' do
        expect(other_request.reload.response_body).to eq(raw_response)
      end

      it 'erases the raw response of the game on the default window' do
        expect(request.reload.response_body).to be_nil
      end
    end
  end

end
