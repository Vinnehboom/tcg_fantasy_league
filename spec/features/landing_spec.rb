require 'rails_helper'

RSpec.describe 'Landing page', :js do
  it 'lets a visitor see every game and pick one' do
    pokemon = create(:game, name: 'Pokemon TCG')
    riftbound = create(:game, name: 'Riftbound')

    visit root_path

    expect(page).to have_content(pokemon.name)
    expect(page).to have_content(riftbound.name)

    click_link pokemon.name

    expect(page).to have_current_path(game_root_path(game: pokemon))
  end
end
