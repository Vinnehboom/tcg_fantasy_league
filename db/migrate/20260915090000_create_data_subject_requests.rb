class CreateDataSubjectRequests < ActiveRecord::Migration[7.1]

  def change
    create_table :data_subject_requests do |t|
      t.references :player, null: false, foreign_key: true
      t.integer :request_type, null: false
      t.integer :status, null: false, default: 0
      t.string :contact_email
      t.text :identity_proof
      t.datetime :actioned_at

      t.timestamps
    end

    add_index :data_subject_requests, :status
  end

end
