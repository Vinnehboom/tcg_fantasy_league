class CreatePrices < ActiveRecord::Migration[7.1]
  def change
    create_table :prices do |t|
      t.references :player, null: false, foreign_key: true
      t.string :external_points
      t.datetime :start_time
      t.datetime :end_time
      t.decimal :value

      t.timestamps
    end
  end
end
