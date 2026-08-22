class AddLabsTournamentIdToTournaments < ActiveRecord::Migration[7.1]

  def change
    add_column :tournaments, :labs_tournament_id, :string
    add_index :tournaments, :labs_tournament_id, unique: true
  end

end
