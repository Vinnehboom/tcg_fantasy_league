module ExternalData

  class RequestRecorder < ApplicationService

    def initialize(game:, kind:, source_url: nil)
      super()
      @game = game
      @kind = kind
      @source_url = source_url
    end

    def call
      request = ExternalRequest.create!(game:, kind:, status: :running, started_at: Time.current, source_url:)

      begin
        result = yield(request)
        records_processed = result.records_processed
        request.requestable = result.requestable
        request.mark_success(records_processed:)
      rescue StandardError => e
        close_as_failure(request, e)
        raise
      end

      request
    end

    private

    attr_reader :game, :kind, :source_url

    def close_as_failure(request, exception)
      write_failure(request, error: "#{exception.class}: #{exception.message}", finished_at: Time.current)
    end

    # update_columns, not update!: a validating save here could itself raise and strand the row as running.
    # rubocop:disable Rails/SkipsModelValidations
    def write_failure(request, error:, finished_at:)
      request.update_columns(status: :failure, error:, finished_at:)
    rescue StandardError => e
      Rails.logger.error(
        "ExternalData::RequestRecorder failed to close request #{request.id} as failure: #{e.class}: #{e.message}"
      )
    end
    # rubocop:enable Rails/SkipsModelValidations

  end

end
