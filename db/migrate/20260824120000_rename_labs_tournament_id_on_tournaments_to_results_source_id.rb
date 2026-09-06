class RenameLabsTournamentIdOnTournamentsToResultsSourceId < ActiveRecord::Migration[7.1]

  def change
    # The PostgreSQL adapter renames the column's index along with the column,
    # so an explicit rename_index here finds no index by the old name.
    rename_column :tournaments, :labs_tournament_id, :results_source_id
  end

end
