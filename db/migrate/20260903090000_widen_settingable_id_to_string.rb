class WidenSettingableIdToString < ActiveRecord::Migration[7.1]

  # `settingable_id` was sized as `bigint` for Season (a plain bigint PK), the
  # only owner Setting had at the time. Game's PK is a string ('PTCG',
  # 'RIFT'), so a bigint column can't hold a Game id. Widening to `string`
  # keeps existing Season-owned rows working (Postgres casts bigint -> text
  # automatically via USING) while making Game a valid owner too.
  def up
    change_column :settings, :settingable_id, :string, using: 'settingable_id::text'
  end

  # Not safely reversible once a Game-owned row exists — a Game id
  # ('PTCG') has no bigint representation to cast back to, unlike the
  # forward cast above, which always has a valid text representation to
  # widen into. Declare that honestly instead of a `down` that silently
  # corrupts or drops data the moment a Game-owned Setting exists.
  def down
    raise ActiveRecord::IrreversibleMigration
  end

end
