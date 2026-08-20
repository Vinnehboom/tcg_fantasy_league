namespace :external_data do
  namespace :ptcg do
    desc 'Update Pokémon TCG players'
    task update_players: [:environment] do
      game = Game.find('PTCG')
      ExternalData::Interface.new(game:, adapter: ExternalData::Pokemon::Tcg::Adapter.new(game:)).update_players
    rescue ActiveRecord::RecordNotFound
      raise "external_data:ptcg:update_players: no Game row with id 'PTCG' — seed it before running this task."
    end

    desc 'Update Pokémon TCG upcoming tournaments'
    task update_tournaments: [:environment] do
      game = Game.find('PTCG')
      ExternalData::Interface.new(game:,
                                  adapter: ExternalData::Pokemon::Tcg::Adapter.new(game:)).update_upcoming_tournaments
    rescue ActiveRecord::RecordNotFound
      raise "external_data:ptcg:update_tournaments: no Game row with id 'PTCG' — seed it before running this task."
    end
  end
end
