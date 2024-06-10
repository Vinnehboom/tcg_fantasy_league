module ExternalData

  module Pokemon

    module Tcg

      class Adapter

        def self.players
          ExternalData::Pokemon::Tcg::Players.all
        end

      end

    end

  end

end
