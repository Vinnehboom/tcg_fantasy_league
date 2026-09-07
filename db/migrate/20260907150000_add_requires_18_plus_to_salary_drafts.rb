class AddRequires18PlusToSalaryDrafts < ActiveRecord::Migration[7.1]

  def change
    add_column :salary_drafts, :requires_18_plus, :boolean, default: false, null: false
  end

end
