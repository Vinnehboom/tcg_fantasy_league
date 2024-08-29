require 'rails_helper'

RSpec.describe 'Tournaments' do
  let(:game) { create(:game) }

  describe '#index' do
    before do
      game
    end

    it 'shows all tournaments' do
      get game_tournaments_path(game:)
      expect(response).to render_template('tournaments/index')
    end
  end
end
