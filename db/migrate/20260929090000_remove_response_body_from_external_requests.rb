class RemoveResponseBodyFromExternalRequests < ActiveRecord::Migration[7.1]

  def change
    remove_column :external_requests, :response_body, :jsonb
  end

end
