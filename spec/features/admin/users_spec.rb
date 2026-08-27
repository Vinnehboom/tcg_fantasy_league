require 'rails_helper'

RSpec.describe 'Admin users' do
  let(:admin) { create(:user, :with_role) }

  before { sign_in_as(admin) }

  describe 'index' do
    it 'lists users by username' do
      user = create(:user)

      visit admin_users_path

      expect(page).to have_content(user.username)
    end
  end

  describe 'show' do
    it "shows the user's details and participations" do
      user = create(:user)
      participation = create(:participation, user:)

      visit admin_user_path(user)

      expect(page).to have_content(user.email)
      expect(page).to have_content(user.username)
      expect(page).to have_link(participation.id.to_s, href: admin_participation_path(participation))
    end
  end
end
