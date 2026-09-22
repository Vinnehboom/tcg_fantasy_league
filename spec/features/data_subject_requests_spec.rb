require 'rails_helper'

RSpec.describe 'Data-subject request form' do
  describe 'new' do
    it 'shows the erase/object request type' do
      create(:player, name: 'Ash Ketchum')
      field = I18n.t('activerecord.attributes.data_subject_request.request_type')
      selected_option = I18n.t('activerecord.enums.data_subject_request.request_type.erase_or_object')

      visit new_data_subject_request_path

      expect(page).to have_select(field, selected: selected_option, disabled: true)
    end
  end

  describe 'create' do
    def select_player(player)
      label = "#{player.name} (#{player.game.name}, #{player.country})"
      select label, from: I18n.t('data_subject_requests.new.player_label')
    end

    it 'queues a request when the requester gives a contact email' do
      player = create(:player, name: 'Ash Ketchum')

      visit new_data_subject_request_path
      select_player(player)
      fill_in 'data_subject_request_contact_email', with: 'ash@example.com'
      click_button I18n.t('data_subject_requests.new.submit')

      expect(page).to have_content(I18n.t('data_subject_requests.create.success'))
      expect(DataSubjectRequest.sole).to be_queued
      expect(DataSubjectRequest.sole.contact_email).to eq('ash@example.com')
    end

    it 'queues a request when the requester gives identity proof instead of an email' do
      player = create(:player, name: 'Ash Ketchum')

      visit new_data_subject_request_path
      select_player(player)
      fill_in 'data_subject_request_identity_proof', with: 'My passport number is 123'
      click_button I18n.t('data_subject_requests.new.submit')

      expect(page).to have_content(I18n.t('data_subject_requests.create.success'))
      expect(DataSubjectRequest.sole).to be_queued
    end

    it 'rejects a submission with neither a contact email nor identity proof' do
      player = create(:player, name: 'Ash Ketchum')

      visit new_data_subject_request_path
      select_player(player)
      click_button I18n.t('data_subject_requests.new.submit')

      expect(page).to have_content(I18n.t('data_subject_requests.create.failed'))
      expect(DataSubjectRequest.count).to eq(0)
    end

    it 'rejects a submission with no player selected, instead of defaulting to one' do
      create(:player, name: 'Ash Ketchum')

      visit new_data_subject_request_path
      fill_in 'data_subject_request_contact_email', with: 'ash@example.com'
      click_button I18n.t('data_subject_requests.new.submit')

      expect(page).to have_content(I18n.t('data_subject_requests.create.failed'))
      expect(DataSubjectRequest.count).to eq(0)
    end

    it 'does not let the requester pick an already-suppressed player' do
      create(:player, :suppressed, name: 'Ash Ketchum')

      visit new_data_subject_request_path

      expect(page).to have_no_content('Ash Ketchum')
    end
  end
end
