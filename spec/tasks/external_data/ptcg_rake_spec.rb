require 'rails_helper'

RSpec.describe 'external_data:ptcg rake tasks', type: :task do
  let(:update_players_task) { Rake::Task['external_data:ptcg:update_players'] }
  let(:update_tournaments_task) { Rake::Task['external_data:ptcg:update_tournaments'] }

  after do
    update_players_task.reenable
    update_tournaments_task.reenable
  end

  describe 'update_players' do
    describe 'when a PTCG game row exists' do
      before { create(:game, id: 'PTCG') }

      it 'imports the scraped players' do
        player = ExternalData::Player.new(attributes: { name: 'Jodie Predovic', country: 'TF',
                                                        external_id: '/players/5', external_points: '791' })
        allow(ExternalData::Pokemon::Tcg::Players).to receive(:all).and_return([player])

        expect { update_players_task.invoke }.to change(Player, :count).by(1)
      end
    end

    describe 'when no PTCG game row exists' do
      it 'raises a semantic error instead of a bare RecordNotFound' do
        message = "external_data:ptcg:update_players: no Game row with id 'PTCG' — seed it before running this task."

        expect { update_players_task.invoke }.to raise_error(RuntimeError, message)
      end
    end
  end

  describe 'update_tournaments' do
    describe 'when a PTCG game row exists' do
      before { create(:game, id: 'PTCG') }

      it 'imports the scraped upcoming tournaments' do
        tournament = ExternalData::Tournament.new(attributes: { name: 'WC 2024', country: 'US',
                                                                external_id: '/tournaments/1',
                                                                starting_date: Faker::Date.forward })
        allow(ExternalData::Pokemon::Tcg::Tournaments).to receive(:upcoming_tournaments).and_return([tournament])

        expect { update_tournaments_task.invoke }.to change(Tournament, :count).by(1)
      end
    end

    describe 'when no PTCG game row exists' do
      it 'raises a semantic error instead of a bare RecordNotFound' do
        message = "external_data:ptcg:update_tournaments: no Game row with id 'PTCG' — " \
                  'seed it before running this task.'

        expect { update_tournaments_task.invoke }.to raise_error(RuntimeError, message)
      end
    end
  end
end
