require 'rails_helper'

RSpec.describe 'Password reset' do
  let(:user) { create(:user, password: 'testtest') }
  let(:game) { create(:game) }

  describe 'requesting a reset' do
    it 'sends a reset email' do
      visit new_user_password_path

      fill_in 'user_email', with: user.email

      expect do
        perform_enqueued_jobs { click_button 'Send me reset password instructions' }
      end.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(page).to have_content(
        'If your email address exists in our database, you will receive a password ' \
        'recovery link at your email address in a few minutes.'
      )
    end

    it 'shows the same neutral message for an email address that is not registered' do
      visit new_user_password_path

      fill_in 'user_email', with: 'not_registered@example.com'

      expect do
        perform_enqueued_jobs { click_button 'Send me reset password instructions' }
      end.not_to change(ActionMailer::Base.deliveries, :count)

      expect(page).to have_content(
        'If your email address exists in our database, you will receive a password ' \
        'recovery link at your email address in a few minutes.'
      )
    end
  end

  describe 'completing a reset from the emailed link' do
    before do
      visit new_user_password_path
      fill_in 'user_email', with: user.email
      perform_enqueued_jobs { click_button 'Send me reset password instructions' }
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
