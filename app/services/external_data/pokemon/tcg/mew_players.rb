module ExternalData

  module Pokemon

    module Tcg

      class MewPlayers

        MEW_BASE_URI = 'https://mew.limitlesstcg.com'.freeze
        RANKINGS_PATH = '/labs/data/tcg/rankings'.freeze
        DIVISION = 'MA'.freeze

        def self.all(season:)
          response = client.get_json(path: RANKINGS_PATH, query: { season:, division: DIVISION })
          parse_players(response)
        end

        def self.client
          ExternalData::JsonApiClient.new(base_uri: MEW_BASE_URI)
        end
        private_class_method :client

        def self.parse_players(response)
          response.fetch('message', []).filter_map { |entry| build_player(entry) }
        end
        private_class_method :parse_players

        def self.build_player(entry)
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
        private_class_method :build_player

      end

    end

  end

end
