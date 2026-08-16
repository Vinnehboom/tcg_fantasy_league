module Admin

  class GamesController < ApplicationController

    def index
      @games = Game.order(:name)
    end

    def show
      @game = Game.find(params[:id])
    end

  end

end
