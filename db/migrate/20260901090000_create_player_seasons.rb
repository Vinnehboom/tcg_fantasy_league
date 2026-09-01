class CreatePlayerSeasons < ActiveRecord::Migration[7.1]

  def change
    create_table :player_seasons do |t|
      t.references :player, null: false, foreign_key: true
      t.references :season, null: false, foreign_key: true

      t.timestamps
    end
    add_index :player_seasons, %i[player_id season_id], unique: true
  end

end
