class AddInternalToSeasons < ActiveRecord::Migration[7.1]

  def change
    add_column :seasons, :internal, :boolean, null: false, default: false
  end

end
