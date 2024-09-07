class AddStatusToParticipation < ActiveRecord::Migration[7.1]
  def change
    add_column :participations, :status, :integer, default: 0
  end
end
