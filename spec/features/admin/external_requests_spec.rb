require 'rails_helper'

RSpec.describe 'Admin external requests' do
  let(:admin) { create(:user, :with_role) }
  let(:game) { create(:game) }

  before { sign_in_as(admin) }

  describe 'index' do
    it 'lists external requests for the selected game' do
      external_request = create(:external_request, :success, game:)
      kind = I18n.t(external_request.kind, scope: %i[activerecord enums external_request kind])

      visit admin_external_requests_path(game: game.id)

      expect(page).to have_content(kind)
      expect(page).to have_content(external_request.records_processed)
    end
  end

  describe 'show' do
    it 'shows one external request in full' do
      external_request = create(:external_request, :success, game:)
      kind = I18n.t(external_request.kind, scope: %i[activerecord enums external_request kind])

      visit admin_external_request_path(external_request)

      expect(page).to have_content(external_request.game.name)
      expect(page).to have_content(kind)
      expect(page).to have_content(external_request.source_url)
    end
  end
end
