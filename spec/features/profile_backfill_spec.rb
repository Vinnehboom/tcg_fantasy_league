require 'rails_helper'

RSpec.describe 'Profile backfill' do
  it 'redirects to the profile-completion form when the country or date of birth is missing' do
    user = create(:user, :incomplete_profile)

    sign_in_with(user, expect_signed_in_flash: false)

    expect(page).to have_current_path(edit_profile_path)
    expect(page).to have_content('Please complete your profile to continue.')
  end

  it 'saves the profile and continues to the normal destination once both fields are filled in' do
    user = create(:user, :incomplete_profile)
    sign_in_with(user, expect_signed_in_flash: false)

    select 'United States', from: 'user_country'
    select (Date.current.year - 30).to_s, from: 'user_date_of_birth_1i'
    select 'January', from: 'user_date_of_birth_2i'
    select '1', from: 'user_date_of_birth_3i'
    click_button I18n.t('helpers.submit.update', model: 'User')

    expect(page).to have_current_path(root_path)
    expect(user.reload.country).to eq('US')
  end

  it 'signs a user with a complete profile in as usual, without a detour through the profile form' do
    user = create(:user, password: 'testtest')

    sign_in_with(user)

    expect(page).to have_current_path(root_path)
  end

  it 're-shows the form with an inline error when the update leaves a field blank' do
    user = create(:user, :incomplete_profile)
    sign_in_with(user, expect_signed_in_flash: false)

    click_button I18n.t('helpers.submit.update', model: 'User')

    expect(page).to have_content("Country can't be blank")
  end
end
