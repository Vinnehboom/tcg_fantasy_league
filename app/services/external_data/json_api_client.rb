module ExternalData

  class JsonApiClient

    class HttpError < ExternalData::Exception

      attr_reader :status, :url

      def initialize(status:, url:)
        @status = status
        @url = url
        super('External API request failed', "GET #{url} returned HTTP #{status}")
      end

    end

    class RateLimitError < HttpError

    end

    class TimeoutError < ExternalData::Exception

      attr_reader :url

      def initialize(url:)
        @url = url
        super('External API request timed out', "GET #{url} timed out")
      end

    end

    def initialize(base_uri:, retry_policy: RetryPolicy.new)
      @base_uri = base_uri
      @retry_policy = retry_policy
    end

    def get_json(path:, query: {})
      url = url_for(path)
      response = fetch(url:, query:)
      JSON.parse(response.body)
    end

    private

    attr_reader :base_uri, :retry_policy

    def fetch(url:, query:, attempt: 1)
      response = perform_request(url:, query:)
      return response if response.code == 200
      return retry_after_rate_limit(response:, url:, query:, attempt:) if response.code == 429

      raise HttpError.new(status: response.code, url:)
    rescue Timeout::Error
      retry_after_timeout(url:, query:, attempt:)
    end

    def retry_after_timeout(url:, query:, attempt:)
      raise TimeoutError.new(url:) if attempt >= retry_policy.max_attempts

      sleep(retry_policy.delay_before_retry(attempt:))
      fetch(url:, query:, attempt: attempt + 1)
    end

    def retry_after_rate_limit(response:, url:, query:, attempt:)
      raise RateLimitError.new(status: response.code, url:) if attempt >= retry_policy.max_attempts

      delay = retry_policy.delay_before_retry(attempt:, retry_after: response.headers['Retry-After'])
      sleep(delay)
      fetch(url:, query:, attempt: attempt + 1)
    end

    def perform_request(url:, query:)
      options = { timeout: retry_policy.timeout }
      options[:query] = query if query.present?
      HTTParty.get(url, **options)
    end

    def url_for(path)
      "#{base_uri}#{path}"
    end

  end

end
