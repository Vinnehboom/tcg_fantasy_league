class CreateResults < ActiveRecord::Migration[7.1]

  def change
    create_table :results do |t|
      t.references :player, null: false, foreign_key: true
      t.references :tournament, null: false, foreign_key: true
      t.integer :placement

      t.timestamps
    end
    add_index :results, %i[player_id tournament_id], unique: true
  end

end
