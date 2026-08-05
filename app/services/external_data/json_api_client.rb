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

    def fetch(url:, query:)
      response = perform_request(url:, query:)
      return response if response.code == 200

      raise HttpError.new(status: response.code, url:)
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
