require 'rails_helper'

RSpec.describe 'Sign out' do
  let(:user) { create(:user, password: 'testtest') }
  let(:game) { create(:game) }

  before do
    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'testtest'
    click_button I18n.t('devise.sessions.sign_in')
  end

  it 'signs the user out' do
    visit game_root_path(game:)

    click_link I18n.t('views.layout.header.logout')

    expect(page).to have_content(I18n.t('devise.sessions.signed_out'))
  end
end
