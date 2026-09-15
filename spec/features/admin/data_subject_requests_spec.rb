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
  end
end
