module Admin

  class PlayersController < ApplicationController

    def index
      @games = Game.order(:name).to_a
      @game = @games.find { |game| game.id == params[:game] } || @games.first
      @players = players_for(@game).page(params[:page])
    end

    def show
      @player = Player.find(params[:id])
      @player_seasons = @player.player_seasons
                               .includes(season: :game, player_season_modifiers: :score_modifier)
                               .references(:season)
                               .order('seasons.start_date')
      @kept_score_modifiers = ScoreModifier.kept.order(:name).to_a
    end

    private

    def players_for(game)
      return Player.none unless game

      game.players.order(:name)
    end

  end

end
