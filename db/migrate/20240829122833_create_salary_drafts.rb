class CreateSalaryDrafts < ActiveRecord::Migration[7.1]
  def change
    create_table :salary_drafts do |t|
      t.references :tournament, null: false, foreign_key: true
      t.integer :price_cap
      t.integer :roster_size

      t.timestamps
    end
  end
end
