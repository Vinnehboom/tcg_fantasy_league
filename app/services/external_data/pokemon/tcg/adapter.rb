module ExternalData

  module Pokemon

    module Tcg

      class Adapter

        def initialize(game:, season: game.current_season)
          @game = game
          @season = season
        end

        def players
          ExternalData::Pokemon::Tcg::LabsPlayers.call(season: current_season.label)
        end

        def upcoming_tournaments
          ExternalData::Pokemon::Tcg::Tournaments.upcoming_tournaments
        end

        private

        attr_reader :game, :season

        def current_season
          season || raise("#{self.class.name}: no Season row covers #{Date.current} for game '#{game.id}' — " \
                          'seed a Season before running this job.')
        end

      end

    end

  end

end
