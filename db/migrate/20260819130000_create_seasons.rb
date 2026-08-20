class CreateSeasons < ActiveRecord::Migration[7.1]

  def change
    create_table :seasons do |t|
      t.string :game_id, null: false
      t.string :label, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end
    add_index :seasons, :game_id
  end

end
