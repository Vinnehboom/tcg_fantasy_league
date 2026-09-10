# every 1.day, at: '9:00 am' do
#   runner "#{ExternalData::ImportPlayersJob.name}.perform_later(game_id: 'PTCG')"
#   runner "#{ExternalData::ImportTournamentsJob.name}.perform_later(game_id: 'PTCG')"
# end

# The job class is named as a string, not interpolated from the constant: whenever
# reads this file as plain Ruby with no Rails environment, so a constant reference
# here raises NameError under `whenever --update-crontab`. The schedule spec
# interpolates the real constant, so a rename still fails the build.
every 1.hour do
  runner 'ExternalData::RetentionJob.perform_later'
end
