class CreatePlayerSeasonModifiers < ActiveRecord::Migration[7.1]

  def change
    create_table :player_season_modifiers do |t|
      t.references :player_season, null: false, foreign_key: true
      t.references :score_modifier, null: false, foreign_key: true

      t.timestamps
    end
    add_index :player_season_modifiers, %i[player_season_id score_modifier_id], unique: true
  end

end
