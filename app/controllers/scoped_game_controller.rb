class ScopedGameController < ApplicationController

  before_action :set_game

  private

  def set_game
    @game = Game.find_by(name: params[:game])
    return if @game

    redirect_to root_path, error: t('games.not_found')
  end

end
