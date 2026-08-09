require 'rails_helper'

module ExternalData

  module Ptcg

    RSpec.describe ImportTournamentsJob do
      subject(:job) { described_class.new }

      describe 'when a PTCG game row exists' do
        let(:tournament) do
          ExternalData::Tournament.new(
            attributes: { name: 'WC 2024', country: 'US', external_id: '/tournaments/1',
                          starting_date: Faker::Date.forward }
          )
        end

        before do
          create(:game, id: 'PTCG')
          allow(ExternalData::Pokemon::Tcg::Tournaments).to receive(:upcoming_tournaments).and_return([tournament])
        end

        it_behaves_like 'an external data import job'

        it 'imports the scraped upcoming tournaments' do
          expect { job.perform_now }.to change(::Tournament, :count).by(1)
        end

        it 'records the fetch against the tournaments kind' do
          job.perform_now

          expect(ExternalRequest.last.kind).to eq('tournaments')
        end
      end

      describe 'when no PTCG game row exists' do
        it 'raises a semantic error instead of a bare RecordNotFound' do
          message = "ExternalData::Ptcg::ImportTournamentsJob: no Game row with id 'PTCG' — seed it before " \
                    'running this job.'

          expect { job.perform_now }.to raise_error(RuntimeError, message)
        end
      end
    end

  end

end
