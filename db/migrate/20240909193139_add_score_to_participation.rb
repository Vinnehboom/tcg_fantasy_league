class AddScoreToParticipation < ActiveRecord::Migration[7.1]
  def change
    add_column :roster_players, :score, :decimal
  end
end
