class RemoveScoreFromPlayer < ActiveRecord::Migration[7.1]
  def change
    remove_column :players, :external_points, :string
  end
end
