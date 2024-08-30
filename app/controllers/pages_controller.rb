class PagesController < ApplicationController

  def landing
    @games = Game.all
    render layout: 'no_header'
  end

  def home
    @game = Game.find_by(id: params[:game])
  end

end
