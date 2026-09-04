class AddDiscardedAtToScoreModifiers < ActiveRecord::Migration[7.1]

  def change
    add_column :score_modifiers, :discarded_at, :datetime
    add_index :score_modifiers, :discarded_at
  end

end
