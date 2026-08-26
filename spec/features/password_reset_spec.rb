require 'rails_helper'

RSpec.describe 'Password reset' do
  let(:user) { create(:user, password: 'testtest') }
  let(:game) { create(:game) }

  describe 'requesting a reset' do
    it 'sends a reset email' do
      visit new_user_password_path

      fill_in 'user_email', with: user.email

      expect { click_button 'Send me reset password instructions' }
        .to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(page).to have_content(I18n.t('devise.passwords.send_instructions'))
    end
  end

  describe 'completing a reset from the emailed link' do
    before do
      visit new_user_password_path
      fill_in 'user_email', with: user.email
      click_button 'Send me reset password instructions'
    end

    it 'sets a new password the user can then sign in with' do
      mail = ActionMailer::Base.deliveries.last
      reset_url = mail.body.encoded[/href="([^"]+)"/, 1]

      visit reset_url

      fill_in 'user_password', with: 'newtestpass'
      fill_in 'user_password_confirmation', with: 'newtestpass'
      click_button 'Change my password'

      expect(page).to have_content(I18n.t('devise.passwords.updated'))

      # Resetting a password signs the user in automatically. Sign out through
      # the header (the redirect target has no header) so the next sign-in
      # attempt below proves the new password actually works.
      visit game_root_path(game:)
      click_link I18n.t('views.layout.header.logout')
      visit new_user_session_path
      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: 'newtestpass'
      click_button I18n.t('devise.sessions.sign_in')

      expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
    end
  end
end
