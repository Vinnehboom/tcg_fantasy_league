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

    def update_players
      ActiveRecord::Base.transaction do
        players.each do |player|
          db_player = Player.find_or_initialize_by(external_id: player[:external_id], game_id: player[:game_id])
          db_player.assign_attributes(player)
          db_player.save!
        end
      end
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
