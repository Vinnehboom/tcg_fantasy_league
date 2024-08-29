class TournamentsController < ScopedGameController

  def index
    @tournaments = @game.tournaments.upcoming.order('starting_date').page(params[:page])
  end

end
