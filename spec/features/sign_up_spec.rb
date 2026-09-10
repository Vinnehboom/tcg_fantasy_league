require 'rails_helper'

RSpec.describe 'Sign up' do
  def select_date_of_birth(years_ago:)
    select (Date.current.year - years_ago).to_s, from: 'user_date_of_birth_1i'
    select 'January', from: 'user_date_of_birth_2i'
    select '1', from: 'user_date_of_birth_3i'
  end

  def sign_up_with(email:, country:, years_ago:, username: email.split('@').first)
    visit new_user_registration_path

    fill_in 'user_email', with: email
    fill_in 'user_username', with: username
    select country, from: 'user_country'
    select_date_of_birth(years_ago:)
    fill_in 'user_password', with: 'testtest'
    fill_in 'user_password_confirmation', with: 'testtest'
  end

  it 'creates a new user with valid details' do
    sign_up_with(email: 'new_player@example.com', country: 'United States', years_ago: 30)

    expect { click_button I18n.t('devise.registrations.sign_up') }.to change(User, :count).by(1)

    expect(page).to have_content(
      'A message with a confirmation link has been sent to your email address. ' \
      'Please follow the link to activate your account.'
    )
  end

  it 'rejects a signup below the digital consent age for the chosen country' do
    sign_up_with(email: 'too_young@example.com', country: 'United Kingdom', years_ago: 10)

    expect { click_button I18n.t('devise.registrations.sign_up') }.not_to change(User, :count)

    expect(page).to have_content('Account not created')
    expect(page).not_to have_content('13')
  end

  it 'accepts a 14-year-old in the UK, where the digital consent age is 13' do
    sign_up_with(email: 'gb_teen@example.com', country: 'United Kingdom', years_ago: 14)

    expect { click_button I18n.t('devise.registrations.sign_up') }.to change(User, :count).by(1)
  end

  it 'rejects a 14-year-old in France, where the digital consent age is 15' do
    sign_up_with(email: 'fr_teen@example.com', country: 'France', years_ago: 14)

    expect { click_button I18n.t('devise.registrations.sign_up') }.not_to change(User, :count)

    expect(page).to have_content('Account not created')
  end

  it 'shows a validation error, not the neutral rejection page, for a future date of birth' do
    travel_to Date.new(Date.current.year, 1, 1) do
      visit new_user_registration_path

      fill_in 'user_email', with: 'future_dob@example.com'
      fill_in 'user_username', with: 'future_dob'
      select 'United Kingdom', from: 'user_country'
      select Date.current.year.to_s, from: 'user_date_of_birth_1i'
      select 'December', from: 'user_date_of_birth_2i'
      select '31', from: 'user_date_of_birth_3i'
      fill_in 'user_password', with: 'testtest'
      fill_in 'user_password_confirmation', with: 'testtest'

      expect { click_button I18n.t('devise.registrations.sign_up') }.not_to change(User, :count)

      expect(page).not_to have_content('Account not created')
      expect(page).to have_content('Date of birth must be less than or equal to')
    end
  end

  it 'blocks sign-in for a freshly signed-up, still-unconfirmed user' do
    sign_up_with(email: 'unconfirmed@example.com', country: 'United States', years_ago: 30)
    click_button I18n.t('devise.registrations.sign_up')

    visit new_user_session_path
    fill_in 'user_email', with: 'unconfirmed@example.com'
    fill_in 'user_password', with: 'testtest'
    click_button I18n.t('devise.sessions.sign_in')

    expect(page).to have_content('You have to confirm your email address before continuing.')
    expect(page).not_to have_content('Signed in successfully.')
  end

  def eligible_signup_params(email:)
    {
      'user[email]' => email,
      'user[username]' => email.split('@').first,
      'user[country]' => 'US',
      'user[date_of_birth(1i)]' => (Date.current.year - 30).to_s,
      'user[date_of_birth(2i)]' => '1',
      'user[date_of_birth(3i)]' => '1',
      'user[password]' => 'testtest',
      'user[password_confirmation]' => 'testtest'
    }
  end

  it 'refuses an immediate retry after a rejection, even with a truthful date of birth' do
    sign_up_with(email: 'retry_attempt@example.com', country: 'United Kingdom', years_ago: 10)
    click_button I18n.t('devise.registrations.sign_up')

    visit new_user_registration_path
    expect(page).to have_content('Account not created')

    params = eligible_signup_params(email: 'retry_attempt_2@example.com')
    expect { page.driver.submit(:post, user_registration_path, params) }.not_to change(User, :count)
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
