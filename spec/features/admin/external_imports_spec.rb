require 'rails_helper'

RSpec.describe 'Admin external imports', :js do
  let(:admin) { create(:user, :with_role) }
  let(:game) { create(:game, :ptcg) }

  it 'triggers a player import from the game page' do
    sign_in_as(admin)
    visit admin_game_path(game)

    click_button I18n.t('admin.games.show.trigger_players')

    expect(page).to have_content(I18n.t('admin.games.show.trigger_success'))
    expect(ExternalData::Ptcg::ImportPlayersJob).to have_been_enqueued
  end
end
