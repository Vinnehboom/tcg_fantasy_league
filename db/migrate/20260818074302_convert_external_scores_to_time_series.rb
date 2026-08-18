class ConvertExternalScoresToTimeSeries < ActiveRecord::Migration[7.1]
  def change
    remove_index :external_scores, column: %i[score player_id], unique: true
    add_column :external_scores, :season, :string
  end
end
