class PlayersController < ScopedGameController

  def index
    @players = @game.players.joins(:external_scores)
                    .group('players.id')
                    .order('max(external_scores.score) desc')
                    .page(params[:page])
  end

end
