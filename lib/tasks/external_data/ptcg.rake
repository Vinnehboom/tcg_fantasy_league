namespace :external_data do
  namespace :ptcg do
    desc 'Update Pokémon TCG players'
    task update_players: [:environment] do
      ExternalData::ImportPlayersJob.perform_now(game_id: 'PTCG')
    end

    desc 'Update Pokémon TCG upcoming tournaments'
    task update_tournaments: [:environment] do
      ExternalData::ImportTournamentsJob.perform_now(game_id: 'PTCG')
    end
  end
end
