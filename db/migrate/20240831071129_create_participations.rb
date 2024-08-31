class CreateParticipations < ActiveRecord::Migration[7.1]
  def change
    create_table :participations do |t|
      t.references :draft, null: false, foreign_key:  { to_table: 'salary_drafts' }
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :participations, [:user_id, :draft_id], unique: true

  end
end
