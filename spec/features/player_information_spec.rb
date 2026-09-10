require 'rails_helper'

RSpec.describe 'Player information notice' do
  it 'marks the whole notice as provisional, not final' do
    visit player_information_path

    expect(page).to have_content('This notice is not final')
  end

  it 'says the data did not come from the players themselves' do
    visit player_information_path

    expect(page).to have_content('We did not get this data from the players it describes')
  end

  it 'names the data controller with a placeholder identity' do
    visit player_information_path

    expect(page).to have_content('[Legal entity name]')
    expect(page).to have_content('[Registered address]')
  end

  it 'gives a placeholder contact address for privacy requests' do
    visit player_information_path

    expect(page).to have_content('[Contact address for privacy and data-subject requests]')
  end

  it 'describes the data it holds about a player' do
    visit player_information_path

    expect(page).to have_content('your name, your country, your finishing places in tournaments')
  end

  it 'names the public source the data came from' do
    visit player_information_path

    expect(page).to have_content('public rankings and results of Limitless TCG')
  end

  it 'gives the purpose and names legitimate interests as the lawful basis' do
    visit player_information_path

    expect(page).to have_content('Our members pick real competitive players')
    expect(page).to have_content('Our lawful basis is legitimate interests')
  end

  it 'gives a placeholder retention period for player data' do
    visit player_information_path

    expect(page).to have_content('[retention period for player data to be confirmed]')
  end

  it 'names Render and Honeybadger as recipients of the data' do
    visit player_information_path

    expect(page).to have_content('Render hosts our application and our database')
    expect(page).to have_content('Honeybadger receives our error reports')
  end

  it 'states that using Render and Honeybadger sends data outside the UK' do
    visit player_information_path

    expect(page).to have_content('Render and Honeybadger are based in the United States')
    expect(page).to have_content('International Data Transfer Addendum')
  end

  it "states the player's rights over their own data" do
    visit player_information_path

    expect(page).to have_content('right to access, correct, erase, restrict, and port your data')
  end

  it 'gives an objection route and says what happens after an objection' do
    visit player_information_path

    expect(page).to have_content('Write to the contact address above and tell us that you object')
    expect(page).to have_content('we remove you from the site')
    expect(page).to have_content('compelling legitimate grounds')
  end

  it 'says a removal is done by hand, so a later import can bring the data back' do
    visit player_information_path

    expect(page).to have_content('We do this by hand at the moment')
  end

  it 'names the ICO and gives a placeholder for any named complaints contact' do
    visit player_information_path

    expect(page).to have_content("Information Commissioner's Office (ICO)")
    expect(page).to have_content('[named data protection contact beyond the ICO to be confirmed]')
  end
end
