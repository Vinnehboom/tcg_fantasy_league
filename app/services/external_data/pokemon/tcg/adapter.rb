module ExternalData

  module Pokemon

    module Tcg

      class Adapter

        def self.players
          ExternalData::Pokemon::Tcg::Players.all
        end

        def self.upcoming_tournaments
          ExternalData::Pokemon::Tcg::Tournaments.upcoming_tournaments
        end

      end

    end

  end

end
