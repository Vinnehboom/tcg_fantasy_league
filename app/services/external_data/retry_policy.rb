module ExternalData

  class RetryPolicy

    attr_reader :timeout

    def initialize(
      timeout: default_timeout,
      retry_delays: default_retry_delays,
      max_retry_after: default_max_retry_after
    )
      @timeout = timeout
      @retry_delays = retry_delays
      @max_retry_after = max_retry_after
    end

    def max_attempts
      retry_delays.size + 1
    end

    def delay_before_retry(attempt:, retry_after: nil)
      capped_retry_after(retry_after) || retry_delays[attempt - 1]
    end

    private

    attr_reader :retry_delays, :max_retry_after

    def capped_retry_after(retry_after)
      return nil unless retry_after.is_a?(Numeric)

      [retry_after, max_retry_after].min
    end

    def default_timeout
      10
    end

    def default_retry_delays
      [0.5, 1.0]
    end

    def default_max_retry_after
      30
    end

  end

end
