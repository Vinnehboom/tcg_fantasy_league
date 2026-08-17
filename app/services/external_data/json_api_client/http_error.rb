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

  end

end
