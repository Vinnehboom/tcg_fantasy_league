require 'rails_helper'

RSpec.describe 'Players index', :js do
  let(:game) { create(:game) }

  it 'lists players sorted by score, highest first' do
    low_scorer = create(:player, game:, name: 'Low Scorer')
    low_scorer.external_scores.create!(score: 100)
    high_scorer = create(:player, game:, name: 'High Scorer')
    high_scorer.external_scores.create!(score: 900)

    visit game_players_path(game:)

    player_rows = page.all('tbody tr', minimum: 1).map(&:text)
    expect(player_rows.first).to include(high_scorer.name)
    expect(player_rows.last).to include(low_scorer.name)
  end

  it 'filters players by country as the visitor picks one, with no manual submit' do
    # Countries are sorted alphabetically for the select's options, so the browser
    # auto-selects 'JP' on load (no blank/prompt option exists). Giving `other` the
    # alphabetically-first country and then explicitly selecting `matching`'s country
    # ('US') makes the `select` call a real state change instead of a no-op
    # re-selection of what was already active.
    matching = create(:player, game:, name: 'Ash Ketchum', country: 'US')
    other = create(:player, game:, name: 'Misty Waterflower', country: 'JP')

    visit game_players_path(game:)
    select 'US', from: I18n.t('activerecord.attributes.player.country')

    # Assert the negative first: this is what actually waits/retries for the
    # Turbo round-trip to land, since it's false until the unfiltered `other`
    # row is gone. Asserting the positive first would pass instantly against
    # the still-visible unfiltered page, without ever waiting for anything.
    expect(page).to have_no_content(other.name)
    expect(page).to have_content(matching.name)
  end

  it 'filters players by name as the visitor types, with no manual submit' do
    # Both players share a known country so the auto-selected country (whichever
    # sorts first alphabetically) never excludes either one - the debounced
    # auto-submit sends both `name` and `country`, and this keeps the example
    # isolated to testing the name filter alone.
    matching = create(:player, game:, name: 'Ash Ketchum', country: 'US')
    other = create(:player, game:, name: 'Misty Waterflower', country: 'US')

    visit game_players_path(game:)
    fill_in I18n.t('activerecord.attributes.player.name'), with: 'Ash'

    # Assert the negative first: this is what actually waits/retries for the
    # Turbo round-trip to land, since it's false until the unfiltered `other`
    # row is gone. Asserting the positive first would pass instantly against
    # the still-visible unfiltered page, without ever waiting for anything.
    expect(page).to have_no_content(other.name)
    expect(page).to have_content(matching.name)
  end
end
