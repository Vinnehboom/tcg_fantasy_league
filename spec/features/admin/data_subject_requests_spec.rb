require 'rails_helper'

RSpec.describe 'Admin data-subject requests' do
  let(:admin) { create(:user, :with_role) }

  before { sign_in_as(admin) }

  describe 'index' do
    it 'lists a queued request by player, type and status, linked to its show page' do
      player = create(:player, name: 'Ash Ketchum')
      data_subject_request = create(:data_subject_request, player:)

      visit admin_data_subject_requests_path

      expect(page).to have_content('Ash Ketchum')
      expect(page).to have_content(I18n.t('activerecord.enums.data_subject_request.request_type.erase_or_object'))
      expect(page).to have_content(I18n.t('activerecord.enums.data_subject_request.status.queued'))
      expect(page).to have_link(href: admin_data_subject_request_path(data_subject_request))
    end
  end

  describe 'show' do
    it 'shows the request details' do
      player = create(:player, name: 'Ash Ketchum')
      data_subject_request = create(:data_subject_request, player:, contact_email: 'ash@example.com')

      visit admin_data_subject_request_path(data_subject_request)

      expect(page).to have_content('Ash Ketchum')
      expect(page).to have_content('ash@example.com')
      expect(page).to have_content(I18n.t('activerecord.enums.data_subject_request.status.queued'))
    end

    it 'offers a way to mark a queued request actioned' do
      data_subject_request = create(:data_subject_request)

      visit admin_data_subject_request_path(data_subject_request)

      expect(page).to have_link(I18n.t('admin.data_subject_requests.show.mark_actioned'))
    end

    it 'does not offer it again once the request is already actioned' do
      data_subject_request = create(:data_subject_request, :actioned)

      visit admin_data_subject_request_path(data_subject_request)

      expect(page).to have_no_link(I18n.t('admin.data_subject_requests.show.mark_actioned'))
    end
  end

  describe 'mark_actioned' do
    it 'flips the request to actioned and suppresses the player' do
      player = create(:player, name: 'Ash Ketchum')
      data_subject_request = create(:data_subject_request, player:)

      visit admin_data_subject_request_path(data_subject_request)
      click_link I18n.t('admin.data_subject_requests.show.mark_actioned')

      expect(page).to have_current_path(admin_data_subject_request_path(data_subject_request))
      expect(data_subject_request.reload).to be_actioned
      expect(player.reload).to be_suppressed
    end
  end
end
