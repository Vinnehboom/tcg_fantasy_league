class CreateRosterPlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :roster_players do |t|
      t.references :player, null: false, foreign_key: true
      t.references :roster, null: false, foreign_key: true

      t.timestamps
    end
  end
end
