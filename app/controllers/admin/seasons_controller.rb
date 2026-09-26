module Admin

  class SeasonsController < ApplicationController

    before_action :set_game

    def index
      @seasons = @game.seasons.order(start_date: :desc)
    end

    private

    def set_game
      @game = Game.find(params[:game_id])
    end

  end

end
