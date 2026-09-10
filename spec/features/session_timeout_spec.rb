require 'rails_helper'

RSpec.describe 'Session timeout' do
  let(:user) { create(:user, password: 'testtest') }

  it 'signs the user out after 31 minutes of inactivity' do
    sign_in_with(user)

    travel 31.minutes do
      visit edit_user_registration_path
    end

    expect(page).to have_content('Your session expired. Please sign in again to continue.')
    expect(page).to have_current_path(new_user_session_path)
  end
end
