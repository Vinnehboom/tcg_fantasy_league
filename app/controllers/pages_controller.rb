class PagesController < ApplicationController

  def landing
    @games = Game.all
    render layout: 'no_header'
  end

  def home
    @game = Game.find_by(id: params[:game])
    @upcoming_drafts = @game.upcoming_drafts.page(params['drafts']).per(10)
    @top_users = User.highscorers(game: @game).page(params['users']).per(10)
  end

end
