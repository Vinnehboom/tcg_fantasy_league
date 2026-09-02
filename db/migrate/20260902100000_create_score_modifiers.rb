class CreateScoreModifiers < ActiveRecord::Migration[7.1]

  def change
    create_table :score_modifiers do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.decimal :value, null: false

      t.timestamps
    end
  end

end
