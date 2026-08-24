class RenameLabsTournamentIdOnTournamentsToResultsSourceId < ActiveRecord::Migration[7.1]

  def change
    rename_column :tournaments, :labs_tournament_id, :results_source_id
    rename_index :tournaments, 'index_tournaments_on_labs_tournament_id', 'index_tournaments_on_results_source_id'
  end

end
