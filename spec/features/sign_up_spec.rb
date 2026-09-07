require 'rails_helper'

RSpec.describe 'Sign up' do
  def select_date_of_birth(years_ago:)
    select (Date.current.year - years_ago).to_s, from: 'user_date_of_birth_1i'
    select 'January', from: 'user_date_of_birth_2i'
    select '1', from: 'user_date_of_birth_3i'
  end

  it 'creates a new user with valid details' do
    visit new_user_registration_path

    fill_in 'user_email', with: 'new_player@example.com'
    fill_in 'user_username', with: 'new_player'
    select 'United States', from: 'user_country'
    select_date_of_birth(years_ago: 30)
    fill_in 'user_password', with: 'testtest'
    fill_in 'user_password_confirmation', with: 'testtest'

    expect { click_button I18n.t('devise.registrations.sign_up') }.to change(User, :count).by(1)

    expect(page).to have_content(I18n.t('devise.registrations.signed_up'))
  end

  it 'rejects a signup below the digital consent age for the chosen country' do
    visit new_user_registration_path

    fill_in 'user_email', with: 'too_young@example.com'
    fill_in 'user_username', with: 'too_young'
    select 'United Kingdom', from: 'user_country'
    select_date_of_birth(years_ago: 10)
    fill_in 'user_password', with: 'testtest'
    fill_in 'user_password_confirmation', with: 'testtest'

    expect { click_button I18n.t('devise.registrations.sign_up') }.not_to change(User, :count)

    expect(page).to have_content('Account not created')
    expect(page).not_to have_content('13')
  end

  it 're-shows the form with an inline error when a required field is left blank' do
    visit new_user_registration_path

    fill_in 'user_email', with: 'no_country@example.com'
    fill_in 'user_username', with: 'no_country'
    fill_in 'user_password', with: 'testtest'
    fill_in 'user_password_confirmation', with: 'testtest'

    expect { click_button I18n.t('devise.registrations.sign_up') }.not_to change(User, :count)

    expect(page).to have_content("Country can't be blank")
    expect(page).to have_field('user_email')
  end
end
