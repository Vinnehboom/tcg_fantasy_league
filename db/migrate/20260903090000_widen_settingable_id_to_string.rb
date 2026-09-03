class WidenSettingableIdToString < ActiveRecord::Migration[7.1]

  # settingable_id was bigint (Season's PK type); Game's PK is a string
  # ('PTCG'), so it needs to be a valid owner too.
  def up
    change_column :settings, :settingable_id, :string, using: 'settingable_id::text'
  end

  # Not reversible once a Game-owned row exists — its id has no bigint
  # representation to cast back to.
  def down
    raise ActiveRecord::IrreversibleMigration
  end

end
