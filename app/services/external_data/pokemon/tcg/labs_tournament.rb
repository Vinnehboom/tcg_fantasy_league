module ExternalData

  module Pokemon

    module Tcg

      class LabsTournament < ApplicationService

        include LabsApi

        TOURNAMENT_PATH = '/labs/data/tcg/tournament'.freeze

        def initialize(tournament_id:, division: DIVISION,
                       client: ExternalData::JsonApiClient.new(base_uri: MEW_BASE_URI))
          @tournament_id = tournament_id
          @division = division
          @client = client
          super()
        end

        def call
          players = Integer(players_value, exception: false)
          players if players&.positive?
        end

        private

        attr_reader :tournament_id, :division, :client

        def players_value
          response.fetch('message', {})['players']
        end

        def response
          @response ||= client.get_json(path: TOURNAMENT_PATH, query: { id: tournament_id, division: })
        end

      end

    end

  end

end
