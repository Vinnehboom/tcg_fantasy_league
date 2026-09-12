class AddSuppressedAtToPlayers < ActiveRecord::Migration[7.1]

  def change
    add_column :players, :suppressed_at, :datetime
    add_index :players, :suppressed_at
  end

end
