module ExternalData

  class JsonApiClient

    class ConnectionError < ExternalData::Exception

      attr_reader :url

      def initialize(url:)
        @url = url
        super('External API connection failed', "GET #{url} failed before a response was received")
      end

    end

  end

end
