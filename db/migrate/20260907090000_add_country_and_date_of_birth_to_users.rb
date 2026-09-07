class AddCountryAndDateOfBirthToUsers < ActiveRecord::Migration[7.1]

  def change
    add_column :users, :country, :string, limit: 2
    add_column :users, :date_of_birth, :date
  end

end
