require 'rails_helper'

module ExternalData

  module Ptcg

    RSpec.describe ImportPlayersJob do
      subject(:job) { described_class.new }

      describe 'when a PTCG game row exists' do
        let(:player) do
          ExternalData::Player.new(
            attributes: { name: 'Jodie Predovic', country: 'TF', external_id: '/players/5', external_points: '791' }
          )
        end

        before do
          create(:game, id: 'PTCG')
          allow(ExternalData::Pokemon::Tcg::Players).to receive(:all).and_return([player])
        end

        it_behaves_like 'an external data import job'

        it 'imports the scraped players' do
          expect { job.perform_now }.to change(::Player, :count).by(1)
        end

        it 'records the fetch against the players kind' do
          job.perform_now

          expect(ExternalRequest.last.kind).to eq('players')
        end
      end

      describe 'when no PTCG game row exists' do
        it 'raises a semantic error instead of a bare RecordNotFound' do
          message = "ExternalData::Ptcg::ImportPlayersJob: no Game row with id 'PTCG' — seed it before running " \
                    'this job.'

          expect { job.perform_now }.to raise_error(RuntimeError, message)
        end
      end
    end

  end

end
