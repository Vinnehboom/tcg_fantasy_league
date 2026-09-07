class AddMinimumAgeToSalaryDrafts < ActiveRecord::Migration[7.1]

  def change
    add_column :salary_drafts, :minimum_age, :integer, default: 0, null: false
  end

end
