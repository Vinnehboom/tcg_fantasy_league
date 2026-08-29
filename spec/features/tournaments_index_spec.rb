require 'rails_helper'

RSpec.describe 'Tournaments index', :js do
  it 'lists the game\'s upcoming tournaments' do
    game = create(:game)
    starting_date = 1.year.from_now.to_date
    tournament = create(:tournament, game:, name: 'Winter Regionals', country: 'JP', starting_date:)

    visit game_tournaments_path(game:)

    expect(page).to have_content(tournament.name)
    expect(page).to have_content(tournament.country)
    expect(page).to have_content(starting_date.strftime('%d-%m-%Y'))
  end
end
