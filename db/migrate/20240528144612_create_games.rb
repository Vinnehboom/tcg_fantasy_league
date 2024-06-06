class CreateGames < ActiveRecord::Migration[7.1]
  def change
    create_table :games do |t|
      t.string :name
      t.string :base_uri

      t.timestamps
    end
  end
end
