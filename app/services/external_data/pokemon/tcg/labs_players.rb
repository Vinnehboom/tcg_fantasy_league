module ExternalData

  module Pokemon

    module Tcg

      class LabsPlayers < ApplicationService

        MEW_BASE_URI = 'https://mew.limitlesstcg.com'.freeze
        RANKINGS_PATH = '/labs/data/tcg/rankings'.freeze
        DIVISION = 'MA'.freeze

        def initialize(season:, client: ExternalData::JsonApiClient.new(base_uri: MEW_BASE_URI))
          @season = season
          @client = client
          super()
        end

        def call
          response = client.get_json(path: RANKINGS_PATH, query: { season:, division: DIVISION })
          parse_players(response)
        end

        private

        attr_reader :season, :client

        def parse_players(response)
          response.fetch('message', []).filter_map { |entry| build_player(entry) }
        end

        def build_player(entry)
          player_id = entry['player_id']
          points = entry['points']
          return if player_id.blank? || points.blank?

          ExternalData::Player.new(
            attributes: {
              external_id: "/players/#{player_id}",
              name: entry['name'],
              country: entry['country'],
              external_points: points
            }
          )
        end

      end

    end

  end

end
