module ExternalData

  class RetentionJob < ApplicationJob

    DEFAULT_RETENTION_HOURS = 24
    MINIMUM_RETENTION_HOURS = 1

    def perform
      ExternalRequest.with_discarded.discarded.delete_all
      ::Game.find_each { |game| erase_expired_response_bodies(game:) }
    end

    private

    # update_all, not a per-row save: erasing row by row loads every expired
    # response_body into memory, which a large audit log can exhaust a worker with.
    # rubocop:disable Rails/SkipsModelValidations
    def erase_expired_response_bodies(game:)
      expired_requests(game:).update_all(response_body: nil, updated_at: Time.current)
    end
    # rubocop:enable Rails/SkipsModelValidations

    def expired_requests(game:)
      ExternalRequest.where(game:)
                     .where(created_at: ...retention_cutoff(game:))
                     .where.not(response_body: nil)
    end

    def retention_cutoff(game:)
      retention_hours(game:).hours.ago
    end

    def retention_hours(game:)
      hours = Integer(configured_hours(game:), exception: false)

      hours&.clamp(MINIMUM_RETENTION_HOURS..) || DEFAULT_RETENTION_HOURS
    end

    def configured_hours(game:)
      settings = Hash.try_convert(game.default_setting&.settings) || {}
      retention = Hash.try_convert(settings['retention']) || {}

      retention['external_request_hours']
    end

  end

end
