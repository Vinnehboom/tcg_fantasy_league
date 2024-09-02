class CreateRosters < ActiveRecord::Migration[7.1]
  def change
    create_table :rosters do |t|
      t.references :participation, null: false, foreign_key: true

      t.timestamps
    end
  end
end
