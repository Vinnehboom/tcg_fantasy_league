class AddGameIdToPlayer < ActiveRecord::Migration[7.1]
  def change
    change_table :players do |t|
      t.references :game
    end
  end
end
