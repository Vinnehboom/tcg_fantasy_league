require 'rails_helper'

RSpec.describe 'Player information notice' do
  before do
    visit player_information_path
  end

  it 'marks the whole notice as provisional, not final' do
    expect(page).to have_content('This notice is not final')
  end

  it 'says the data did not come from the players themselves' do
    expect(page).to have_content('We did not get this data from the players it describes')
  end

  it 'names the data controller with a placeholder identity' do
    expect(page).to have_content('[Legal entity name]')
    expect(page).to have_content('[Registered address]')
  end

  it 'gives a placeholder contact address for privacy requests' do
    expect(page).to have_content('[Contact address for privacy and data-subject requests]')
  end

  it 'describes the data it holds about a player' do
    expect(page).to have_content('your name, your country, the identifier that the source uses for you')
    expect(page).to have_content('your finishing places in tournaments, and your ranking points or rating')
  end

  it 'names the public source the data came from' do
    expect(page).to have_content('public rankings and results of Limitless TCG')
  end

  it 'names every real source, and PTCG is the only game with a registered import adapter' do
    expect(Game.registrations.keys).to eq(%w[PTCG])
    expect(page).to have_content('public rankings and results of Limitless TCG')
  end

  it 'gives the purpose under its own heading' do
    expect(page).to have_content('Our members pick real competitive players')
  end

  it 'names legitimate interests as the lawful basis, under its own heading' do
    expect(page).to have_css('h2', exact_text: 'Our lawful basis')
    expect(page).to have_content('Our lawful basis is legitimate interests')
  end

  it 'gives a placeholder retention period for player data' do
    expect(page).to have_content('[retention period for player data to be confirmed]')
  end

  it 'gives a placeholder for who receives the data' do
    expect(page).to have_css('h2', exact_text: 'Who receives your data')
    expect(page).to have_content('is still being decided and will be confirmed here before launch')
  end

  it 'states how long it keeps the raw response of an import' do
    expect(page).to have_content('We keep the raw response for 24 hours after the import')
  end

  it 'states how often it erases an expired raw response' do
    expect(page).to have_content('A job that runs every hour then erases the raw response')
  end

  it 'names the same window the retention job applies by default' do
    expect(page).to have_content("for #{ExternalData::RetentionJob::DEFAULT_RETENTION_HOURS} hours after the import")
  end

  it 'gives a placeholder for whether data transfers outside the UK' do
    expect(page).to have_css('h2', exact_text: 'Transfers outside the UK')
    expect(page).to have_content('depends on the final hosting decision, and will be confirmed here before launch')
  end

  it "states the player's rights over their own data" do
    expect(page).to have_content('right to access, correct, erase, and restrict your data')
    expect(page).to have_content('right to object to our use of it')
  end

  it 'claims no portability right, because the basis is legitimate interests' do
    expect(page).to have_no_content('port your data')
    expect(page).to have_content('Data portability is a right only where the processing rests on consent')
  end

  it 'offers a copy of the data anyway, as something beyond the statutory minimum' do
    expect(page).to have_content('we will send you a copy of what we hold')
  end

  it 'gives an objection route and says what happens after an objection' do
    expect(page).to have_content('Write to the contact address above and tell us that you object')
    expect(page).to have_content('we remove you from the site')
    expect(page).to have_content('compelling legitimate grounds')
  end

  it 'says a removal is done by hand, so a later import can bring the data back' do
    expect(page).to have_content('We do this by hand at the moment')
  end

  it 'names the ICO and gives a placeholder for any named complaints contact' do
    expect(page).to have_content("Information Commissioner's Office (ICO)")
    expect(page).to have_content('[named data protection contact beyond the ICO to be confirmed]')
  end
end
