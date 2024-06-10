module ExternalData

  class Interface < ApplicationService

    def initialize(game)
      @game = game
      @adapter = select_adapter
      super()
    end

    def players
      players = @adapter.players
      players.compact_blank.map { |player| { game_id: @game.id, **player } }
    end

    private

    def select_adapter
      case @game.name
      when 'PTCG'
        Pokemon::Tcg::Adapter
      else
        OfflineAdapter
      end
    end

  end

end
