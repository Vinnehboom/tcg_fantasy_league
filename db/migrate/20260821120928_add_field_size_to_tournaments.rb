class AddFieldSizeToTournaments < ActiveRecord::Migration[7.1]

  def change
    add_column :tournaments, :field_size, :integer
  end

end
