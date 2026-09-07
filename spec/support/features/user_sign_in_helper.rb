module Features

  module UserSignInHelper

    def sign_in_with(user, expect_signed_in_flash: true)
      visit new_user_session_path

      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: 'testtest'
      click_button I18n.t('devise.sessions.sign_in')
      expect(page).to have_content(I18n.t('devise.sessions.signed_in')) if expect_signed_in_flash
    end

  end

end
