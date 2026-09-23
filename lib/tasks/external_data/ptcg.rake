namespace :external_data do
  namespace :ptcg do
    desc 'Update Pokémon TCG players. Writes an audited ExternalRequest row; a transient ' \
         'timeout or rate limit is retried automatically instead of raising to this terminal.'
    task update_players: [:environment] do
      ExternalData::ImportPlayersJob.perform_now(game_id: 'PTCG')
    end

    desc 'Update Pokémon TCG upcoming tournaments. Writes an audited ExternalRequest row; a ' \
         'transient timeout or rate limit is retried automatically instead of raising to this terminal.'
    task update_tournaments: [:environment] do
      ExternalData::ImportTournamentsJob.perform_now(game_id: 'PTCG')
    end
  end
end
