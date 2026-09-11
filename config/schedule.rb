# every 1.day, at: '9:00 am' do
#   runner "#{ExternalData::ImportPlayersJob.name}.perform_later(game_id: 'PTCG')"
#   runner "#{ExternalData::ImportTournamentsJob.name}.perform_later(game_id: 'PTCG')"
# end
