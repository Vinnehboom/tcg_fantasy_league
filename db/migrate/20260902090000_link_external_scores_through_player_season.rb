class LinkExternalScoresThroughPlayerSeason < ActiveRecord::Migration[7.1]

  def change
    remove_column :external_scores, :season, :string
    remove_reference :external_scores, :player, foreign_key: true, index: true
    # No default is possible for a reference column, and none is needed: dev/test data
    # gets wiped and no backfill runs, so the table is empty at migration time.
    add_reference :external_scores, :player_season, null: false, foreign_key: true # rubocop:disable Rails/NotNullColumn
  end

end
