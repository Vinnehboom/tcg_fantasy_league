module Admin

  class SeasonsController < ApplicationController

    before_action :set_game

    def index
      @seasons = @game.seasons.order(start_date: :desc)
    end

    def new
      @season = @game.seasons.new
      authorize @season
    end

    def edit
      @season = @game.seasons.find(params[:id])
      authorize @season
    end

    def create
      @season = @game.seasons.new(create_params)
      authorize @season
      if @season.save
        redirect_to admin_game_seasons_path(@game), notice: t('.success')
      else
        flash.now[:error] = t('.failed')
        render :new, status: :unprocessable_content
      end
    end

    def update
      @season = @game.seasons.find(params[:id])
      authorize @season
      if @season.update(update_params)
        redirect_to admin_game_seasons_path(@game), notice: t('.success')
      else
        flash.now[:error] = t('.failed')
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_game
      @game = Game.find(params[:game_id])
    end

    def create_params
      params.require(:season).permit(:label, :start_date, :end_date)
    end

    def update_params
      params.require(:season).permit(:label, :end_date)
    end

  end

end
