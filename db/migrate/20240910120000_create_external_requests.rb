class CreateExternalRequests < ActiveRecord::Migration[7.1]

  def change
    create_table :external_requests do |t|
      t.references :game, null: false, foreign_key: true, type: :string
      t.integer :kind, null: false
      t.integer :status, null: false, default: 0
      t.integer :records_processed, null: false, default: 0
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.text :error
      t.jsonb :response_body
      t.string :source_url
      t.references :requestable, polymorphic: true, null: true

      t.timestamps
    end
  end

end
