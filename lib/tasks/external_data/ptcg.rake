namespace :external_data do
  namespace :ptcg do
    desc 'Update Pokémon TCG players. Writes an audited ExternalRequest row. A transient ' \
         'timeout or rate limit re-enqueues the job on the in-process queue, but this task ' \
         'does not wait for that retry. The task exits with status 0 before the retry runs, ' \
         'so the retry is lost. Check the ExternalRequest row for a status of failure. A ' \
         'clean exit does not mean the import succeeded.'
    task update_players: [:environment] do
      ExternalData::ImportPlayersJob.perform_now(game_id: 'PTCG')
    end

    desc 'Update Pokémon TCG upcoming tournaments. Writes an audited ExternalRequest row. A ' \
         'transient timeout or rate limit re-enqueues the job on the in-process queue, but ' \
         'this task does not wait for that retry. The task exits with status 0 before the ' \
         'retry runs, so the retry is lost. Check the ExternalRequest row for a status of ' \
         'failure. A clean exit does not mean the import succeeded.'
    task update_tournaments: [:environment] do
      ExternalData::ImportTournamentsJob.perform_now(game_id: 'PTCG')
    end
  end
end
