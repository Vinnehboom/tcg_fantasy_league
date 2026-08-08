module ExternalData

  module Pokemon

    module Tcg

      class Adapter

        def players
          ExternalData::Pokemon::Tcg::Players.all
        end

        def upcoming_tournaments
          ExternalData::Pokemon::Tcg::Tournaments.upcoming_tournaments
        end

      end

    end

  end

end
