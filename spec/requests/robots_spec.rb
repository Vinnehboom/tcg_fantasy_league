require 'rails_helper'

RSpec.describe 'Robots' do
  describe 'GET /robots.txt' do
    it 'disallows the player paths' do
      get '/robots.txt'

      expect(response.body).to include('Disallow: /*/players')
    end
  end
end
