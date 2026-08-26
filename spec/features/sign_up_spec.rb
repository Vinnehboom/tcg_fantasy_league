require 'rails_helper'

RSpec.describe 'Sign up' do
  it 'creates a new user with valid details' do
    visit new_user_registration_path

    fill_in 'user_email', with: 'new_player@example.com'
    fill_in 'user_username', with: 'new_player'
    fill_in 'user_password', with: 'testtest'
    fill_in 'user_password_confirmation', with: 'testtest'

    expect { click_button I18n.t('devise.registrations.sign_up') }.to change(User, :count).by(1)

    expect(page).to have_content(I18n.t('devise.registrations.signed_up'))
  end
end
