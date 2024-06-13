class CreateTournaments < ActiveRecord::Migration[7.1]
  def change
    create_table :tournaments do |t|
      t.string :name
      t.string :external_id
      t.string :country
      t.references :game, null: false, foreign_key: true
      t.string :format
      t.date :starting_date

      t.timestamps
    end
  end
end
