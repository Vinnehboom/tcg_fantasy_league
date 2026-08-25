module ExternalData

  module Pokemon

    module Tcg

      class LabsStandings < ApplicationService

        include LabsApi

        STANDINGS_PATH = '/labs/data/tcg/standings'.freeze

        def initialize(tournament_id:, division: DIVISION,
                       client: ExternalData::JsonApiClient.new(base_uri: MEW_BASE_URI))
          @tournament_id = tournament_id
          @division = division
          @client = client
          super()
        end

        def call
          entries.filter_map { |entry| build_result(entry) unless dropped_or_dqed?(entry) }
        end

        def self.entrant_count(**)
          new(**).entrant_count
        end

        def entrant_count
          entries.length
        end

        private

        attr_reader :tournament_id, :division, :client

        def entries
          @entries ||= response.fetch('message', [])
        end

        def response
          @response ||= client.get_json(path: STANDINGS_PATH, query: { tournamentId: tournament_id, division: })
        end

        # The wire type of dropped/dqed isn't confirmed (unlike opw/opw2, no quirk is called out for them) -
        # normalize defensively rather than trust Ruby truthiness, since a numeric-boolean 0/"0" would otherwise
        # be misread as "dropped".
        def dropped_or_dqed?(entry)
          ActiveModel::Type::Boolean.new.cast(entry['dropped']) || ActiveModel::Type::Boolean.new.cast(entry['dqed'])
        end

        def build_result(entry)
          player_id = entry['player_id']
          name = entry['name']
          placement = entry['placement']
          return if player_id.blank? || name.blank? || placement.blank?

          ExternalData::Result.new(
            attributes: {
              player_external_id: "/players/#{player_id}",
              player_name: name,
              player_country: entry['country'],
              placement:
            }
          )
        end

      end

    end

  end

end
