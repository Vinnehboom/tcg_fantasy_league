namespace :external_data do
  desc 'Update players'
  task update_players: [:environment] do |_task, _args|
    games = Game.all
    games.each do |game|
      interface = ExternalData::Interface.new(game:)
      interface.update_players
    end
  end

  desc 'Update tournaments'
  task update_tournaments: [:environment] do |_task, _args|
    games = Game.all
    games.each do |game|
      interface = ExternalData::Interface.new(game:)
      interface.update_upcoming_tournaments
    end
  end

  def find_game(game_id)
    Game.find(game_id)
  end
end
