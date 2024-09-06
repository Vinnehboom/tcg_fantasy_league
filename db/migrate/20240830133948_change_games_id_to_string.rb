class ChangeGamesIdToString < ActiveRecord::Migration[7.1]

  class Game < ActiveRecord::Base
    self.table_name = 'games'
    has_many :players
    has_many :tournaments
  end

  class NewGame < ActiveRecord::Base
    self.table_name = 'new_games'
    has_many :new_tournaments
    has_many :new_players
  end

  class Player < ActiveRecord::Base
    self.table_name = 'players'
    belongs_to :game
  end

  class NewPlayer < ActiveRecord::Base
    self.table_name = 'new_players'
    belongs_to :game, class_name: "NewGame", foreign_key: :game_id
  end

  class Tournament < ActiveRecord::Base
    self.table_name = 'tournaments'
    belongs_to :game
  end

  class NewTournament < ActiveRecord::Base
    self.table_name = 'new_tournaments'
    belongs_to :game, class_name: "NewGame", foreign_key: :game_id
  end


  def change
    create_table :new_games, id: :string do |t|
      t.string :name
      t.string "base_uri"
      t.timestamps

    end

    ActiveRecord::Base.transaction do
      Game.all.each do |game|
        NewGame.create(id: game.name, name: game.name, base_uri: game.base_uri)
      end
    end

    create_table :new_players do |p|
      p.string :name
      p.string :country
      p.string :external_id
      p.string :external_points
      p.references :game, null: false, foreign_key: { to_table: 'new_games'}, type: :string
      p.timestamps

    end

    ActiveRecord::Base.transaction do
      Player.all.each do |player|
        NewPlayer.create!(**player.attributes, game: NewGame.find(player.game.name))
      end
    end

    create_table :new_tournaments do |q|
      q.string :name
      q.string :external_id
      q.string :country
      q.string :format
      q.date :starting_date
      q.references :game, null: false, foreign_key: { to_table: 'new_games'}, type: :string
      q.timestamps

    end

    ActiveRecord::Base.transaction do
      Tournament.all.each do |tournament|
        NewTournament.create!(**tournament.attributes, game: NewGame.find(tournament.game.name))
      end
    end

    remove_foreign_key "external_scores", "players"
    remove_foreign_key "salary_drafts", "tournaments"
    remove_index "external_scores", "player_id"
    remove_index "salary_drafts", "tournament_id"
    drop_table :tournaments
    drop_table :players
    drop_table :games

    rename_table 'new_games', 'games'
    rename_table 'new_players', 'players'
    rename_table 'new_tournaments', 'tournaments'
    add_foreign_key "external_scores", "players"
    add_foreign_key "salary_drafts", "tournaments"
    add_index :external_scores, :player_id
    add_index :salary_drafts, :tournament_id

  end


end
