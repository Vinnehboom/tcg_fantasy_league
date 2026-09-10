require 'rails_helper'

RSpec.describe 'Pages' do
  describe 'GET /player-information' do
    it 'answers a visitor who is not signed in' do
      get player_information_path

      expect(response).to have_http_status(:ok)
    end

    it 'sends no noindex, so the notice stays findable by the players it describes' do
      get player_information_path

      expect(response.body).not_to include('name="robots"')
    end

    it 'is not disallowed by robots.txt, which only excludes the player paths' do
      get '/robots.txt'

      expect(response.body).not_to include(player_information_path)
    end
  end
end
