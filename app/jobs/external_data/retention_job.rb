module ExternalData

  class RetentionJob < ApplicationJob

    RETENTION_DAYS = 90

    def perform
      ExternalRequest.with_discarded.discarded.delete_all
      ExternalRequest.where(created_at: ...RETENTION_DAYS.days.ago).delete_all
    end

  end

end
