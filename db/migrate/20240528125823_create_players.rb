class CreatePlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :players do |t|
      t.string :name
      t.string :country
      t.string :external_id
      t.string :external_points

      t.timestamps
    end
  end
end
