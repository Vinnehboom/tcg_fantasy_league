every 1.day, at: '9:00 am' do
  rake "external_data:update_players"
  rake "external_data:update_upcoming_tournaments"
end