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
end
