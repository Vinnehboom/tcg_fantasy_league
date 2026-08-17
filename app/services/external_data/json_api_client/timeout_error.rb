module ExternalData

  class JsonApiClient

    class TimeoutError < ExternalData::Exception

      attr_reader :url

      def initialize(url:)
        @url = url
        super('External API request timed out', "GET #{url} timed out")
      end

    end

  end

end
