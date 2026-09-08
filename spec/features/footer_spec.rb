require 'rails_helper'

RSpec.describe 'Footer' do
  it 'links to the privacy notice from the landing page' do
    visit root_path

    click_link I18n.t('views.layout.footer.privacy_link')

    expect(page).to have_current_path(privacy_path)
  end

  it 'links to the terms of service from the landing page' do
    visit root_path

    click_link I18n.t('views.layout.footer.terms_link')

    expect(page).to have_current_path(terms_path)
  end

  it 'gives the footer a dark background so its white links stay visible' do
    visit root_path

    expect(page).to have_css('footer.bg-dark')
  end

  it 'shows on a page that renders with the top header too' do
    game = create(:game)

    visit game_root_path(game:)

    expect(page).to have_link(href: privacy_path)
    expect(page).to have_link(href: terms_path)
  end
end
