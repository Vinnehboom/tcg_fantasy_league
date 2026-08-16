class AddDiscardedAtToExternalRequests < ActiveRecord::Migration[7.1]

  def change
    add_column :external_requests, :discarded_at, :datetime
    add_index :external_requests, :discarded_at
  end

end
