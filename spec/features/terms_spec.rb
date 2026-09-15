require 'rails_helper'

RSpec.describe 'Terms of Service' do
  it 'marks the page as a draft, not final, reviewed terms' do
    visit terms_path

    expect(page).to have_content('This page is not final')
  end

  it 'names the operator with a placeholder identity' do
    visit terms_path

    expect(page).to have_content('[Legal entity name]')
    expect(page).to have_content('[Registered address]')
  end

  it 'states the sign-up age by country' do
    visit terms_path

    expect(page).to have_content('13 in the United Kingdom and Belgium')
    expect(page).to have_content('15 in France')
    expect(page).to have_content('16 in every other country')
  end

  it 'states the minimum age for a sponsored draft' do
    visit terms_path

    expect(page).to have_content('You must be 18 or older to enter a draft marked this way')
  end

  it 'describes account responsibilities' do
    visit terms_path

    expect(page).to have_content('You must keep your password safe')
  end

  it 'states the rules for using the service and the grounds for suspension' do
    visit terms_path

    expect(page).to have_content('You must not cheat, use more than one account for yourself')
  end

  it 'describes the license a user grants for their own content' do
    visit terms_path

    expect(page).to have_content('You keep ownership of the content you submit')
    expect(page).to have_content('You give us a license to show this content')
  end

  it 'reserves sponsored drafts as a future feature with terms to come' do
    visit terms_path

    expect(page).to have_content('sponsored drafts that award a real prize are a planned feature, not live yet')
  end

  it 'states that no payment is collected today' do
    visit terms_path

    expect(page).to have_content('We do not charge for any feature today')
  end

  it 'states that the service is provided with no refunds' do
    visit terms_path

    expect(page).to have_content('We provide the service with no refunds')
  end

  it 'states it is not affiliated with any game publisher covered by the service' do
    visit terms_path

    expect(page).to have_content('not affiliated with, and are not endorsed by, Play! Pokémon')
    expect(page).to have_content('The Pokémon Company, or any other game publisher')
  end

  it 'excludes liability to the extent the law allows' do
    visit terms_path

    expect(page).to have_content('we exclude our liability to you for any loss')
  end

  it 'names the governing law and the courts with jurisdiction' do
    visit terms_path

    expect(page).to have_content('The law of England and Wales governs these terms')
    expect(page).to have_content('The courts of England and Wales have exclusive jurisdiction')
  end

  it 'gives a placeholder contact address for legal notices' do
    visit terms_path

    expect(page).to have_content('[Contact address for legal notices]')
  end

  it 'links to the Privacy notice from the shared footer' do
    visit terms_path

    click_link I18n.t('views.layout.footer.privacy_link')

    expect(page).to have_current_path(privacy_path)
  end
end
