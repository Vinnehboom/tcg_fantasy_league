class TournamentsController < ScopedGameController

  def index
    @tournaments = @game.tournaments.order('starting_date').page(params[:page])
  end

end
