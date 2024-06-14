require 'rails_helper'

RSpec.describe 'Tournaments' do
  describe '#index' do
    it 'shows all tournaments' do
      get tournaments_path
      expect(response).to render_template('tournaments/index')
    end
  end
end
