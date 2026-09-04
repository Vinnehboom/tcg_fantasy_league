require 'rails_helper'

RSpec.describe 'demo rake tasks', type: :task do
  let(:seed_task) { Rake::Task['demo:seed'] }
  let(:reseed_task) { Rake::Task['demo:reseed'] }

  after do
    seed_task.reenable
    reseed_task.reenable
    ENV.delete('CONFIRM')
  end

  describe 'seed' do
    it 'populates players, tournaments, history and drafts for every demo game' do
      seed_task.invoke

      expect(Player.count).to be_positive
      expect(SalaryDraft.count).to be_positive
      expect(Tournament.where('external_id LIKE ?', '/tournaments/past-%').count).to be_positive
    end
  end

  describe 'reseed' do
    context 'without CONFIRM=yes' do
      it 'does not truncate anything' do
        create(:game)

        reseed_task.invoke

        expect(Game.count).to eq(1)
      end
    end

    context 'with CONFIRM=yes' do
      it 'resets and repopulates the demo dataset' do
        create(:game, id: 'STALE')
        ENV['CONFIRM'] = 'yes'

        reseed_task.invoke

        expect(Game.exists?(id: 'STALE')).to be(false)
        expect(Player.count).to be_positive
      end
    end
  end
end
