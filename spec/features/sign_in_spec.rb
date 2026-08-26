require 'rails_helper'

RSpec.describe 'Sign in' do
  let(:user) { create(:user, password: 'testtest') }

  it 'signs the user in with valid credentials' do
    visit new_user_session_path

    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'testtest'
    click_button I18n.t('devise.sessions.sign_in')

    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
  end
end
