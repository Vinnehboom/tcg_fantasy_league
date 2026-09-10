require 'rails_helper'

RSpec.describe 'Privacy notice' do
  it 'marks the whole notice as provisional, not final' do
    visit privacy_path

    expect(page).to have_content('This notice is not final')
  end

  it 'names the data controller with a placeholder identity' do
    visit privacy_path

    expect(page).to have_content('[Legal entity name]')
    expect(page).to have_content('[Registered address]')
  end

  it 'gives a placeholder contact address for privacy requests' do
    visit privacy_path

    expect(page).to have_content('[Contact address for privacy and data-subject requests]')
  end

  it 'describes the data it processes' do
    visit privacy_path

    expect(page).to have_content('email address, username, country, and date of birth')
  end

  it 'gives the purpose and the lawful basis for each use' do
    visit privacy_path

    expect(page).to have_content('run your account, run salary drafts and rosters')
    expect(page).to have_content('perform our contract with you')
    expect(page).to have_content('legitimate interest in running the game')
  end

  it 'gives a placeholder retention period' do
    visit privacy_path

    expect(page).to have_content('[retention period to be confirmed]')
  end

  it 'states how long it keeps the raw response of an import' do
    visit privacy_path

    expect(page).to have_content('We keep the raw response for 24 hours after the import')
  end

  it 'states how often it erases an expired raw response' do
    visit privacy_path

    expect(page).to have_content('A job that runs every hour then erases the raw response')
  end

  it 'names Render and Honeybadger as recipients of the data' do
    visit privacy_path

    expect(page).to have_content('Render hosts our application and our database')
    expect(page).to have_content('Honeybadger receives our error reports')
  end

  it 'states that using Render and Honeybadger sends data outside the UK' do
    visit privacy_path

    expect(page).to have_content('Render and Honeybadger are based in the United States')
    expect(page).to have_content('International Data Transfer Addendum')
  end

  it "states the visitor's rights over their own data" do
    visit privacy_path

    expect(page).to have_content('right to access, correct, erase, and port your data')
  end

  it 'links to the separate notice published for the players it tracks' do
    visit privacy_path

    click_link I18n.t('pages.privacy.player_information_link')

    expect(page).to have_current_path(player_information_path)
  end

  it 'names the ICO and gives a placeholder for any named complaints contact' do
    visit privacy_path

    expect(page).to have_content("Information Commissioner's Office (ICO)")
    expect(page).to have_content('[named data protection contact beyond the ICO to be confirmed]')
  end
end
