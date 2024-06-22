class PlayersController < ScopedGameController

  def index
    @players = @game.players.order('external_points::integer desc').page(params[:page])
  end

end
