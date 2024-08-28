class CreateExternalScores < ActiveRecord::Migration[7.1]
  def change
    create_table :external_scores do |t|
      t.references :player, null: false, foreign_key: true
      t.integer :score

      t.timestamps
    end
    add_index :external_scores, [:score, :player_id], unique: true

  end
end
