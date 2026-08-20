require 'rails_helper'

module ExternalData

  module Ptcg

    RSpec.describe ImportPlayersJob do
      subject(:job) { described_class.new }

      describe 'when a PTCG game row exists' do
        let(:player) do
          ExternalData::Player.new(
            attributes: { name: 'Jodie Predovic', country: 'TF', external_id: '/players/5', external_points: '791',
                          season: '2026' }
          )
        end

        before do
          game = create(:game, id: 'PTCG')
          create(:season, game:, start_date: 1.month.ago.to_date, end_date: 1.month.from_now.to_date, label: '2026')
          allow(ExternalData::Pokemon::Tcg::LabsPlayers).to receive(:call).and_return([player])
        end

        it_behaves_like 'an external data import job'

        it 'imports the fetched players' do
          expect { job.perform_now }.to change(::Player, :count).by(1)
        end

        it 'tags the imported player\'s score with the current season' do
          job.perform_now

          expect(::Player.last.external_scores.last.season).to eq('2026')
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
