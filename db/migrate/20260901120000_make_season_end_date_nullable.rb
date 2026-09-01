class MakeSeasonEndDateNullable < ActiveRecord::Migration[7.1]

  def change
    change_column_null :seasons, :end_date, true
  end

end
