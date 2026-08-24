class CreateGameSettings < ActiveRecord::Migration[7.1]

  def change
    create_table :game_settings do |t|
      t.references :season, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end
  end

end
