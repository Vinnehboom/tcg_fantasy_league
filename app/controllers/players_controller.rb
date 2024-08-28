class PlayersController < ApplicationController

  def index
    @players = Player.joins(:external_scores)
                     .group('players.id')
                     .order('max(external_scores.score) desc')
                     .page(params[:page])
  end

end
