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

        def results(tournament:)
          ExternalData::Pokemon::Tcg::LabsStandings.call(tournament_id: results_source_id_for(tournament))
        end

        def field_size(tournament:)
          tournament_id = results_source_id_for(tournament)

          ExternalData::Pokemon::Tcg::LabsTournament.call(tournament_id:) ||
            ExternalData::Pokemon::Tcg::LabsStandings.entrant_count(tournament_id:)
        end

        private

        attr_reader :game, :season

        def current_season
          season || raise("#{self.class.name}: no Season row covers #{Date.current} for game '#{game.id}' — " \
                          'seed a Season before running this job.')
        end

        def results_source_id_for(tournament)
          tournament.results_source_id ||
            raise("#{self.class.name}: no results_source_id set on tournament ##{tournament.id} " \
                  "('#{tournament.name}') — resolve it (e.g. via admin) before fetching Pokemon results.")
        end

      end

    end

  end

end
