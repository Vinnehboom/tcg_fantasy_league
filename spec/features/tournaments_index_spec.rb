require 'rails_helper'

RSpec.describe 'Tournaments index', :js do
  it 'lists the game\'s upcoming tournaments' do
    game = create(:game)
    tournament = create(:tournament, game:, name: 'Winter Regionals', country: 'JP')

    visit game_tournaments_path(game:)

    expect(page).to have_content(tournament.name)
    expect(page).to have_content(tournament.country)
    expect(page).to have_content(I18n.l(tournament.starting_date))
  end
end
