module ExternalData

  module Pokemon

    module Tcg

      class Scraper

        include HTTParty
        base_uri 'https://limitlesstcg.com'

      end

    end

  end

end
