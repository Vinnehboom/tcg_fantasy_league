require 'rails_helper'

RSpec.describe 'Players index', :js do
  let(:game) { create(:game) }

  it 'lists players sorted by score, highest first' do
    low_scorer = create(:player, game:, name: 'Low Scorer')
    low_scorer.external_scores.create(score: 100)
    high_scorer = create(:player, game:, name: 'High Scorer')
    high_scorer.external_scores.create(score: 900)

    visit game_players_path(game:)

    player_rows = page.all('tbody tr').map(&:text)
    expect(player_rows.first).to include(high_scorer.name)
    expect(player_rows.last).to include(low_scorer.name)
  end

  it 'filters players by country as the visitor picks one, with no manual submit' do
    matching = create(:player, game:, name: 'Ash Ketchum', country: 'JP')
    other = create(:player, game:, name: 'Misty Waterflower', country: 'US')

    visit game_players_path(game:)
    select 'JP', from: I18n.t('activerecord.attributes.player.country')

    expect(page).to have_content(matching.name)
    expect(page).to have_no_content(other.name)
  end

  it 'filters players by name as the visitor types, with no manual submit' do
    matching = create(:player, game:, name: 'Ash Ketchum')
    other = create(:player, game:, name: 'Misty Waterflower')

    visit game_players_path(game:)
    fill_in I18n.t('activerecord.attributes.player.name'), with: 'Ash'

    expect(page).to have_content(matching.name)
    expect(page).to have_no_content(other.name)
  end
end
