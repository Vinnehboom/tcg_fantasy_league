module ExternalData

  class JsonApiClient

    class InvalidResponseError < ExternalData::Exception

      MAX_BODY_SNIPPET_LENGTH = 200

      attr_reader :url, :body_snippet

      def initialize(url:, body:)
        @url = url
        @body_snippet = body.to_s.scrub.truncate(MAX_BODY_SNIPPET_LENGTH)
        super('External API response was not valid JSON', "GET #{url} returned a body that failed JSON parsing")
      end

    end

  end

end
